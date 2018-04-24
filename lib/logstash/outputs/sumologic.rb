# encoding: utf-8
require "logstash/json"
require "logstash/namespace"
require "logstash/outputs/base"
require "logstash/plugin_mixins/http_client"
require 'thread'
require "uri"
require "zlib"
require "stringio"
require "socket"

# Now you can use logstash to deliver logs to Sumo Logic
#
# Create a HTTP Source
# in your Sumo Logic account and you can now use logstash to parse your log and 
# send your logs to your account at Sumo Logic.
#
class LogStash::Outputs::SumoLogic < LogStash::Outputs::Base
  include LogStash::PluginMixins::HttpClient
  
  config_name "sumologic"

  CONTENT_TYPE = "Content-Type"
  CONTENT_TYPE_LOG = "text/plain"
  CONTENT_TYPE_GRAPHITE = "application/vnd.sumologic.graphite"
  CONTENT_TYPE_CARBON2 = "application/vnd.sumologic.carbon2"
  CATEGORY_HEADER = "X-Sumo-Category"
  HOST_HEADER = "X-Sumo-Host"
  NAME_HEADER = "X-Sumo-Name"
  CLIENT_HEADER = "X-Sumo-Client"
  TIMESTAMP_FIELD = "@timestamp"
  METRICS_NAME_PLACEHOLDER = "*"
  GRAPHITE = "graphite"
  CARBON2 = "carbon2"
  CONTENT_ENCODING = "Content-Encoding"
  DEFLATE = "deflate"
  GZIP = "gzip"
  ALWAYS_EXCLUDED = [ "@timestamp", "@version" ]

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

  # Hold messages for at least (x) seconds as a pile; 0 means sending every events immediately  
  config :interval, :validate => :number, :default => 0

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
    @source_host = Socket.gethostname unless @source_host

    # initialize request pool
    @request_tokens = SizedQueue.new(@pool_max)
    @pool_max.times { |t| @request_tokens << true }
    @timer = Time.now
    @pile = Array.new
    @semaphore = Mutex.new
    connect
  end # def register

  public
  def multi_receive(events)
    events.each { |event| receive(event) }
    client.execute!
  end # def multi_receive
  
  public
  def receive(event)
    begin
 
      if event == LogStash::SHUTDOWN
        finished
        return
      end

      content = event2content(event)
      queue_and_send(content)

    rescue
      log_failure(
        "Error when processing event",
        :event => event
      )
    end
  end # def receive

  public
  def close
    @semaphore.synchronize {
      send_request(@pile.join($/))
      @pile.clear
    }
    client.close
  end # def close


  private
  def connect
    # TODO: ping endpoint make sure config correct
  end # def connect
  
  private
  def queue_and_send(content)
    if @interval <= 0 # means send immediately
      send_request(content)
    else
      @semaphore.synchronize {
        now = Time.now
        @pile << content

        if now - @timer > @interval # ready to send
          send_request(@pile.join($/))
          @timer = now
          @pile.clear
        end
      }
    end
  end

  private
  def send_request(content)
    token = @request_tokens.pop
    body = compress(content)
    headers = get_headers()

    request = client.send(:parallel).send(:post, @url, :body => body, :headers => headers)
    request.on_complete do
      @request_tokens << token
    end

    request.on_success do |response|
      if response.code < 200 || response.code > 299
        log_failure(
          "HTTP response #{response.code}",
          :body => body,
          :headers => headers
      )
      end
    end

    request.on_failure do |exception|
      log_failure(
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
    if @metrics || @fields_as_metrics
      event2metrics(event)
    else
      event2log(event)
    end
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

  def event_as_metrics(event)
    hash = event2hash(event)
    acc = {}
    hash.keys.each do |field|
      value = hash[field]
      dotify(acc, field, value, nil)
    end
    acc
  end # def event_as_metrics

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
  end

 private
  def expand_hash(hash, event)
    hash.reduce({}) do |acc, kv|
      k, v = kv
      exp_k = expand(k, event)
      exp_v = expand(v, event)
      acc[exp_k] = exp_v
      acc
    end # def expand_hash
  end
  
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

end # class LogStash::Outputs::SumoLogic
