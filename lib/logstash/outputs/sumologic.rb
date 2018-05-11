# encoding: utf-8
require "logstash/json"
require "logstash/namespace"
require "logstash/outputs/base"
require "logstash/plugin_mixins/http_client"
require "net/https"
require "socket"
require "stringio"
require 'thread'
require "uri"
require "zlib"

# Now you can use logstash to deliver logs to Sumo Logic
#
# Create a HTTP Source
# in your Sumo Logic account and you can now use logstash to parse your log and 
# send your logs to your account at Sumo Logic.
#
class LogStash::Outputs::SumoLogic < LogStash::Outputs::Base
  declare_threadsafe!

  require "logstash/outputs/sumologic/common"
  require "logstash/outputs/sumologic/payload_builder"
  require "logstash/outputs/sumologic/header_builder"
  
  include LogStash::PluginMixins::HttpClient
  include LogStash::Outputs::SumoLogic::Common
  include LogStash::Outputs::SumoLogic::PayloadBuilder
  include LogStash::Outputs::SumoLogic::HeaderBuilder

  config_name "sumologic"

  # The URL to send logs to. This should be given when creating a HTTP Source
  # on Sumo Logic web app. See http://help.sumologic.com/Send_Data/Sources/HTTP_Source
  config :url, :validate => :string, :required => true

  # Define the source category metadata
  config :source_category, :validate => :string

  # Define the source host metadata
  config :source_host, :validate => :string

  # Define the source name metadata
  config :source_name, :validate => :string

  # Include extra HTTP headers on request if needed 
  config :extra_headers, :validate => :hash

  # Compress the payload 
  config :compress, :validate => :boolean, :default => false

  # The encoding method of compress
  config :compress_encoding, :validate =>:string, :default => DEFLATE

  # Accumulate events in (x) seconds as a pile/request; 0 means sending every events in isolated requests
  config :interval, :validate => :number, :default => 0

  # Accumulate events for up to (x) bytes as a pile/request; messages larger than this size will be sent in isolated requests
  config :pile_max, :validate => :number, :default => 1024000

  # Max # of events can be hold in memory before sending
  config :queue_max, :validate => :number, :default => 4096

  # Max # of HTTP senders working in parallel
  config :sender_max, :validate => :number, :default => 10

  # The formatter of log message, by default is message with timestamp and host as prefix
  # Use %{@json} tag to send whole event
  config :format, :validate => :string, :default => "%{@timestamp} %{host} %{message}"

  # Override the structure of @json tag with the given key value pairs
  config :json_mapping, :validate => :hash
  
  # Send metric(s) if configured. This is a hash with k as metric name and v as metric value
  # Both metric names and values support dynamic strings like %{host}
  # For example: 
  #     metrics => { "%{host}/uptime" => "%{uptime_1m}" }
  config :metrics, :validate => :hash

  # Create metric(s) automatically from @json fields if configured. 
  config :fields_as_metrics, :validate => :boolean, :default => false
  
  config :fields_include, :validate => :array, :default => [ ]
  
  config :fields_exclude, :validate => :array, :default => [ ]

  # Defines the format of the metric, support "graphite" or "carbon2"
  config :metrics_format, :validate => :string, :default => CARBON2

  # Define the metric name looking, the placeholder '*' will be replaced with the actual metric name
  # For example:
  #     metrics => { "uptime.1m" => "%{uptime_1m}" }
  #     metrics_name => "mynamespace.*"
  # will produce metrics as:
  #     "mynamespace.uptime.1m xxx 1234567"
  config :metrics_name, :validate => :string, :default => METRICS_NAME_PLACEHOLDER

  # For carbon2 metrics format only, define the intrinsic tags (which will be used to identify the metrics)
  # There is always an intrinsic tag as "metric" which value is from metrics_name
  config :intrinsic_tags, :validate => :hash, :default => {}

  # For carbon2 metrics format only, define the meta tags (which will NOT be used to identify the metrics)
  config :meta_tags, :validate => :hash, :default => {}
  
  public
  def register

    connect()

    @queue_max = 1 if @queue_max < 1
    @sender_max = 1 if @sender_max < 1
    
    @format = "%{@json}" if @format.nil? || @format.empty?
    
    @pile = Array.new
    @pile_size = 0
    @semaphore = Mutex.new

    @queue = SizedQueue.new(@queue_max)

    @request_tokens = SizedQueue.new(@sender_max)
    @sender_max.times { |t| @request_tokens << t }

    @is_running = true

    start_piler()
    start_sender()

  end # def register

  public
  def multi_receive(events)
    events.each { |event| receive(event) }
    if @interval <= 0
      client.execute!
    end
  end # def multi_receive
  
  public
  def receive(event)
    begin
      log_dbg("received event", :event => event)
      content = event2content(event)
      if @interval <= 0
        send_request(content)
      else
        pile_input(content)
      end
    rescue Exception => ex
      log_err(
        "Error when processing event",
        :event => event,
        :exception => ex
      )
    end
  end # def receive

  public
  def close
    @is_running = false
    enqueue_pile()
    drain_queue()
    client.close
  end # def close

  private
  def connect()
    uri = URI.parse(@url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri.request_uri)
    res = http.request(request)
    if puts res.code != 200
      log_err(
        "Cannot connect to given url",
        :url => @url,
        :code => res.code
      )
    end
  end # def connect
  
  private
  def start_piler()
    Thread.new { 
      while @is_running
        enqueue_pile()
        Stud.stoppable_sleep(@interval) { !@is_running }
      end # while
    }
  end # def start_piler
  
  private
  def start_sender()
    Thread.new { 
      while @is_running
        dequeue_and_send()
      end # while
    }
  end # def start_sender

  private
  def pile_input(content)
    @semaphore.synchronize {
      if @pile_size + content.length > @pile_max
        enqueue_pile()
      end
      @pile << content
      @pile_size += content.length
    }
  end # def pile_in
  
  private
  def enqueue_pile()
    if @pile_size > 0
      @semaphore.synchronize {
        if @pile_size > 0
          @queue << @pile.join($/)
          @pile.clear
          @pile_size = 0
        end
      }
    end
  end # def enqueue_pile

  private
  def dequeue_and_send()
    while !@request_tokens.empty? && !@queue.empty?
      send_request(@queue.pop())
    end
    client.execute!
  end # def dequeue_and_send

  private
  def drain_queue()
    while !@queue.empty?
      dequeue_and_send()
    end
  end # def drain_queue

  private
  def send_request(content)
    token = @request_tokens.pop()
    body = compress(content)
    headers = get_headers()

    request = client.send(:parallel).send(:post, @url, :body => body, :headers => headers)
    request.on_complete do
      @request_tokens << token
    end

    request.on_success do |response|
      if response.code < 200 || response.code > 299
        log_err(
          "HTTP response #{response.code}",
          :body => body,
          :headers => headers
      )
      end
    end

    request.on_failure do |exception|
      log_err(
        "Could not fetch URL",
        :body => body,
        :headers => headers,
        :message => exception.message,
        :class => exception.class.name,
        :backtrace => exception.backtrace
      )
    end

    request.call
  end # def send_request
  
  private
  def compress(content)
    if @compress
      if @compress_encoding == GZIP
        result = gzip(content)
        result.bytes.to_a.pack('c*')
      else
        Zlib::Deflate.deflate(content)
      end
    else
      content
    end
  end # def compress
  
  private
  def gzip(content)
    stream = StringIO.new("w")
    stream.set_encoding("ASCII")
    gz = Zlib::GzipWriter.new(stream)
    gz.write(content)
    gz.close
    stream.string.bytes.to_a.pack('c*')
  end # def gzip

<<<<<<< HEAD
  private
  def get_headers()

    base = {}
    base = @extra_headers if @extra_headers.is_a?(Hash)

    base[CATEGORY_HEADER] = @source_category if @source_category
    base[HOST_HEADER] = @source_host if @source_host
    base[NAME_HEADER] = @source_name if @source_name
    base[CLIENT_HEADER] = 'logstash-output-sumologic'
    
    if @compress
      if @compress_encoding == GZIP
        base[CONTENT_ENCODING] = GZIP
      elsif 
        base[CONTENT_ENCODING] = DEFLATE
      else
        log_failure(
          "Unrecogonized compress encoding",
          :encoding => @compress_encoding
        )
      end
    end

    if @metrics || @fields_as_metrics
      if @metrics_format == CARBON2
        base[CONTENT_TYPE] = CONTENT_TYPE_CARBON2
      elsif @metrics_format == GRAPHITE
        base[CONTENT_TYPE] = CONTENT_TYPE_GRAPHITE
      else
        log_failure(
          "Unrecogonized metrics format",
          :format => @metrics_format
        )
      end
    else
      base[CONTENT_TYPE] = CONTENT_TYPE_LOG
    end
    
    base

  end # def get_headers

  private 
  def event2content(event)
    content = if @metrics || @fields_as_metrics
      event2metrics(event)
    else
      event2log(event)
    end
    log_debug("encode event to content", :content => content)
    content
  end # def event2content

  private
  def event2log(event)
    @format = "%{@json}" if @format.nil? || @format.empty?
    expand(@format, event)
  end # def event2log

  private
  def event2metrics(event)
    timestamp = get_timestamp(event)
    source = expand_hash(@metrics, event) unless @fields_as_metrics
    source = event_as_metrics(event) if @fields_as_metrics
    source.flat_map { |key, value|
      get_single_line(event, key, value, timestamp)
    }.reject(&:nil?).join("\n")
  end # def event2metrics

  private
  def event_as_metrics(event)
    hash = event2hash(event)
    acc = {}
    hash.keys.each do |field|
      value = hash[field]
      dotify(acc, field, value, nil)
    end
    acc
  end # def event_as_metrics

  private
  def get_single_line(event, key, value, timestamp)
    full = get_metrics_name(event, key)
    if !ALWAYS_EXCLUDED.include?(full) &&  \
      (fields_include.empty? || fields_include.any? { |regexp| full.match(regexp) }) && \
      !(fields_exclude.any? {|regexp| full.match(regexp)}) && \
      is_number?(value)
      if @metrics_format == CARBON2
        @intrinsic_tags["metric"] = full
        "#{hash2line(@intrinsic_tags, event)} #{hash2line(@meta_tags, event)}#{value} #{timestamp}"
      else
        "#{full} #{value} #{timestamp}" 
      end
    end
  end # def get_single_line

  private
  def dotify(acc, key, value, prefix)
    pk = prefix ? "#{prefix}.#{key}" : key.to_s
    if value.is_a?(Hash)
      value.each do |k, v|
        dotify(acc, k, v, pk)
      end
    elsif value.is_a?(Array)
      value.each_with_index.map { |v, i|
        dotify(acc, i.to_s, v, pk)
      }
    else
      acc[pk] = value
    end
  end # def dotify

  private
  def expand(template, event)
    hash = event2hash(event)
    dump = LogStash::Json.dump(hash)
    template = template.gsub("%{@json}") { dump }
    event.sprintf(template)
  end # def expand

  private 
  def event2hash(event)
    if @json_mapping
      @json_mapping.reduce({}) do |acc, kv|
        k, v = kv
        acc[k] = event.sprintf(v)
        acc
      end
    else
      event.to_hash
    end
  end # def map_event

  private
  def is_number?(me)
    me.to_f.to_s == me.to_s || me.to_i.to_s == me.to_s
  end # def is_number?

  private
  def expand_hash(hash, event)
    hash.reduce({}) do |acc, kv|
      k, v = kv
      exp_k = expand(k, event)
      exp_v = expand(v, event)
      acc[exp_k] = exp_v
      acc
    end
  end # def expand_hash
  
  private
  def get_timestamp(event)
    event.get(TIMESTAMP_FIELD).to_i
  end # def get_timestamp

  private
  def get_metrics_name(event, name)
    name = @metrics_name.gsub(METRICS_NAME_PLACEHOLDER) { name } if @metrics_name
    event.sprintf(name)
  end # def get_metrics_name

  private
  def hash2line(hash, event)
    if (hash.is_a?(Hash) && !hash.empty?)
      expand_hash(hash, event).flat_map { |k, v|
        "#{k}=#{v} "
      }.join()
    else
      ""
    end
  end # hash2line

  private
  def log_failure(message, opts)
    @logger.error(message, opts)
  end # def log_failure

  private
  def log_debug(message, opts)
    # @logger.debug(message, opts)
    puts 
    puts message + " " + opts.to_s
  end # def log_debug

=======
>>>>>>> divide header and payload builder
end # class LogStash::Outputs::SumoLogic
