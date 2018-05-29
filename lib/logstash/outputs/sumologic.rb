# encoding: utf-8
require "logstash/event"
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
  require "logstash/outputs/sumologic/compressor"
  require "logstash/outputs/sumologic/header_builder"
  require "logstash/outputs/sumologic/message_queue"
  require "logstash/outputs/sumologic/monitor"
  require "logstash/outputs/sumologic/payload_builder"
  require "logstash/outputs/sumologic/piler"
  require "logstash/outputs/sumologic/sender"
  require "logstash/outputs/sumologic/statistics"
  
  include LogStash::PluginMixins::HttpClient
  include LogStash::Outputs::SumoLogic::Common

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
  config :sender_max, :validate => :number, :default => 100

  # The formatter of log message, by default is message with timestamp and host as prefix
  # Use %{@json} tag to send whole event
  config :format, :validate => :string, :default => DEFAULT_LOG_FORMAT

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

  # Define the metric name looking, the placeholder "*" will be replaced with the actual metric name
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
  
  # For messages fail to send or get 429/503/504 response, try to resend after (x) seconds; don't resend if (x) < 0
  config :sleep_before_requeue, :validate => :number, :default => 30

  # Sending throughput data as metrics
  config :stats_enabled, :validate => :boolean, :default => false

  # Sending throughput data points every (x) seconds
  config :stats_interval, :validate => :number, :default => 60

  attr_reader :stats
  
  def register
    set_logger(@logger)
    @stats = Statistics.new()
    @queue = MessageQueue.new(@stats, config)
    @builder = PayloadBuilder.new(@stats, config)
    @piler = Piler.new(@queue, @stats, config)
    @monitor = Monitor.new(@queue, @stats, config)
    @sender = Sender.new(client, @queue, @stats, config)
    if @sender.connect()
      @sender.start()
      @piler.start()
      @monitor.start()
    else
      throw "connection failed, please check the url and retry"
    end
  end # def register

  def multi_receive(events)
    # events.map { |e| receive(e) }
    begin
      content = Array(events).map { |event| @builder.build(event) }.join($/)
      @queue.enq(content)
      @stats.record_multi_input(events.size, content.bytesize)
    rescue Exception => exception
      log_err(
        "Error when processing events",
        :events => events,
        :message => exception.message,
        :class => exception.class.name,
        :backtrace => exception.backtrace
    )
    end
  end # def multi_receive
  
  def receive(event)
    begin
      content = @builder.build(event)
      @piler.input(content)
    rescue Exception => exception
      log_err(
        "Error when processing event",
        :event => event,
        :message => exception.message,
        :class => exception.class.name,
        :backtrace => exception.backtrace
    )
    end
  end # def receive

  def close
    @monitor.stop()
    @piler.stop()
    @sender.stop()
    client.close()
  end # def close

end # class LogStash::Outputs::SumoLogic
