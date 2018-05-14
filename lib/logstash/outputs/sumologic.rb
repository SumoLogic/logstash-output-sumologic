# encoding: utf-8
require "logstash/json"
require "logstash/namespace"
require "logstash/outputs/base"
require "logstash/plugin_mixins/http_client"

# Now you can use logstash to deliver logs to Sumo Logic
#
# Create a HTTP Source
# in your Sumo Logic account and you can now use logstash to parse your log and 
# send your logs to your account at Sumo Logic.
#
class LogStash::Outputs::SumoLogic < LogStash::Outputs::Base
  declare_threadsafe!

  require "logstash/outputs/sumologic/common"
  require "logstash/outputs/sumologic/statistics"
  require "logstash/outputs/sumologic/payload_builder"
  require "logstash/outputs/sumologic/header_builder"
  require "logstash/outputs/sumologic/piler"
  require "logstash/outputs/sumologic/sender"
  
  include LogStash::PluginMixins::HttpClient
  include LogStash::Outputs::SumoLogic::Common
  include LogStash::Outputs::SumoLogic::PayloadBuilder
  include LogStash::Outputs::SumoLogic::HeaderBuilder
  include LogStash::Outputs::SumoLogic::Sender

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
  
  attr_reader :stats
  
  public
  def register

    @queue_max = 10 if @queue_max < 10
    @sender_max = 1 if @sender_max < 1
    @format = "%{@json}" if @format.nil? || @format.empty?
    @compress_encoding = @compress_encoding.downcase
    @metrics_format = @metrics_format.downcase

    connect()
    @stats = Statistics.new()
    @piler = Piler.new(@interval, @pile_max, @queue_max, @stats)
    @piler.start()
    start_sender()

  end # def register

  public
  def multi_receive(events)
    events.each { |event| receive(event) }
  end # def multi_receive
  
  public
  def receive(event)
    begin
      log_dbg("received event", :event => event)
      content = build_payload(event)
      @piler.input(content)
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
    @piler.stop()
    stop_sender()
  end # def close

<<<<<<< HEAD
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

end # class LogStash::Outputs::SumoLogic
