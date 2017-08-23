# encoding: utf-8
require "logstash/json"
require "logstash/namespace"
require "logstash/outputs/base"
require "logstash/plugin_mixins/http_client"
require 'thread'
require "uri"
require "zlib"
require "stringio"

# Now you can use logstash to deliver logs to Sumo Logic
#
# Create a HTTP Source
# in your Sumo Logic account and you can now use logstash to parse your log and 
# send your logs to your account at Sumo Logic.
#
class LogStash::Outputs::SumoLogic < LogStash::Outputs::Base
  include LogStash::PluginMixins::HttpClient
  
  config_name "sumologic"

  # The URL to send logs to. This should be given when creating a HTTP Source
  # on Sumo Logic web app. See http://help.sumologic.com/Send_Data/Sources/HTTP_Source
  config :url, :validate => :string, :required => true

  # This lets you pre populate the structure and parts from the event into @json tag
  config :json_mapping, :validate => :hash

  # Define the source category metadata
  config :source_category, :validate => :string

  # Define the source host metadata
  config :source_host, :validate => :string

  # Define the source name metadat
  config :source_name, :validate => :string

  # Include extra HTTP headers on request if needed 
  config :extra_headers, :validate => :hash

  # Compress the payload 
  config :compress, :validate => :boolean, :default => false

  # The encoding method of compress
  config :compress_encoding, :validate =>:string, :default => "defalte"

  # Hold messages for at least (x) seconds as a pile; 0 means sending every events immediately  
  config :interval, :validate => :number, :default => 0

  # The formatter of log message, by default is message with timestamp and host as prefix
  # use %{@json} tag to send whole event
  config :format, :validate => :string, :default => "%{@timestamp} %{host} %{message}"

  # Send metric(s) if configured. This is a hash with k as metric name and v as metric value
  # Both metric names and values support dynamic strings like %{host}
  # For example: 
  #     metrics => { "%{host}/uptime" => "%{uptime_1m}" }
  config :metrics, :validate => :hash
  
  # Defines the format of the metric, support "graphite" or "carbon2"
  config :metrics_format, :validate => :string, :default => "graphite"

  # Define the metric name looking, the placeholder '*' will be replaced with the actual metric name
  # For example:
  #     metrics => { "uptime.1m" => "%{uptime_1m}" }
  #     metrics_name => "mynamespace.*"
  # will produce metrics as:
  #     "mynamespace.uptime.1m xxx 1234567"
  config :metrics_name, :validate => :string, :default => "*"

  # For carbon2 metrics format only, define the intrinsic tags (which will be used to identify the metrics)
  # There is always an intrinsic tag as "name" => <metrics name>
  config :metrics_intrinsic_tags, :validate => :hash, :default => {}

  # For carbon2 metrics format only, define the meta tags (which will NOT be used to identify the metrics)
  # source_category, source_host and source_name will be passed in if exist
  config :metrics_meta_tags, :validate => :hash, :default => {}
  
  CONTENT_TYPE_LOG = "text/plain"
  CONTENT_TYPE_GRAPHITE = "application/vnd.sumologic.graphite"
  CONTENT_TYPE_CARBON2 = "application/vnd.sumologic.carbon2"
  HOST_HEADER = "X-Sumo-Host"
  CATEGORY_HEADER = "X-Sumo-Category"
  NAME_HEADER = "X-Sumo-Name"
  TIMESTAMP_FIELD = "@timestamp"
  METRIC_PLACEHOLDER = "*"

  public
  def register
    @source_host = `hostname`.strip unless @source_host
    @metrics_meta_tags["_sourceCategory"] = @source_category if @source_category
    @metrics_meta_tags["_sourceName"] = @source_name if @source_name
    @metrics_meta_tags["_sourceHost"] = @source_host if @source_host

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
    if event == LogStash::SHUTDOWN
      finished
      return
    end

    content = event2content(event)
    queue_and_send(content)
    
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
    # TODO: ping endpoint
  end # def connect
  
  private
  def queue_and_send(content)
    if @interval <= 0 # means send immediately
      send_request(content)
    else
      @semaphore.synchronize {
        now = Time.now
        @pile << event

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
      if @compress_encoding == "gzip"
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
    base.merge(@extra_headers) if @extra_headers

    base[CATEGORY_HEADER] = @source_category if @source_category
    base[HOST_HEADER] = @source_host if @source_host
    base[HOST_HEADER] = `hostname`.strip unless @source_host
    base[NAME_HEADER] = @source_name if @source_name
    
    if @compress
      if @compress_encoding == "gzip"
        base["Content-Encoding"] = "gzip"
      else
        base["Content-Encoding"] = "deflate"
      end
    end

    if @metrics
      if @metrics_format == "carbon2"
        base["Content-Type"] = CONTENT_TYPE_CARBON2
      else
        base["Content-Type"] = CONTENT_TYPE_GRAPHITE
      end
    else
      base["Content-Type"] = CONTENT_TYPE_LOG
    end
    
    base

  end # def get_headers

  private 
  def event2content(event)
    if @metrics
      if @metrics_format == "carbon2"
        event2carbon2(event)
      else
        event2graphite(event)
      end
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
  def expand(template, event)
    template = template.gsub("%{@json}", LogStash::Json.dump(event2hash(event))) if template.include? "%{@json}"
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
  def event2graphite(event)
    timestamp = get_timestamp(event)
    expand_hash(@metrics, event).flat_map { |key, value|
      "#{get_metric_name(event, key)} #{value} #{timestamp}"
    }.join('\n')
  end # def event2graphite

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
  def get_metric_name(event, name)
    name = @metrics_name.gsub(METRIC_PLACEHOLDER, name) if @metrics_name
    event.sprintf(name)
  end # def get_metric_name

  private
  def event2carbon2(event)
    timestamp = get_timestamp(event)
    
    expand_hash(@metrics, event).flat_map { |key, value|
      @metrics_intrinsic_tags["name"] = get_metric_name(event, key)
      "#{hash2line(@metrics_intrinsic_tags, event)}  #{hash2line(@metrics_meta_tags, event)} #{value} #{timestamp}"
    }.join('\n')

  end # def event2carbon2

  private
  def hash2line(hash, event)
    if (hash.is_a?(Hash))
      expand_hash(hash, event).flat_map { |k, v|
        "#{k}=#{v}" 
      }.join(' ')
    else
      ""
    end
  end # hash2line

  private
  def log_failure(message, opts)
    @logger.error(message, opts)
  end # def log_failure

end # class LogStash::Outputs::SumoLogic