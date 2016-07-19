# encoding: utf-8
require "logstash/json"
require "logstash/namespace"
require "logstash/outputs/base"
require "logstash/plugin_mixins/http_client"
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
  include LogStash::PluginMixins::HttpClient
  
  config_name "sumologic"
  
  # The hostname to send logs to. This should be given when creating a HTTP Source
  # on Sumo Logic web app http://help.sumologic.com/Send_Data/Sources/HTTP_Source
  config :url, :validate => :string, :required => true

  # Include extra HTTP headers on request if needed 
  config :extra_headers, :validate => :hash, :default => []

  # The formatter of message, by default is message with timestamp as prefix
  config :format, :validate => :string, :default => "%{@timestamp} %{host} %{message}"

  # Hold messages for at least (x) seconds as a pile; 0 means sending every events immediately  
  config :interval, :validate => :number, :default => 0

  # Compress the payload 
  config :compress, :validate => :boolean, :default => false

  public
  def register
    # initialize request pool
    @request_tokens = SizedQueue.new(@pool_max)
    @pool_max.times { |t| @request_tokens << true }
    @timer = Time.now
    @pile = Array.new
    @semaphore = Mutex.new
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

    content = event.sprintf(@format)
    
    if @interval <= 0 # means send immediately
      send_request(content)
      return
    end

    @semaphore.synchronize {
      now = Time.now
      @pile << content

      if now - @timer > @interval # ready to send
        send_request(@pile.join($/))
        @timer = now
        @pile.clear
      end
    }
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
  def send_request(content)
    token = @request_tokens.pop
    body = if @compress
      Zlib::Deflate.deflate(content)
    else
      content
    end
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
  def get_headers()
    base = { "Content-Type" => "text/plain" }
    base["Content-Encoding"] = "deflate" if @compress
    return base.merge(@extra_headers)
  end # def get_header
  
  private
  def log_failure(message, opts)
    @logger.error(message, opts)
  end # def log_failure

end # class LogStash::Outputs::SumoLogic