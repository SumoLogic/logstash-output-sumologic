# encoding: utf-8
require "net/https"
require "socket"
require "thread"
require "uri"
require "logstash/outputs/sumologic/common"
require "logstash/outputs/sumologic/compressor"
require "logstash/outputs/sumologic/header_builder"
require "logstash/outputs/sumologic/statistics"
require "logstash/outputs/sumologic/message_queue"

module LogStash; module Outputs; class SumoLogic;
  class Sender

    include LogStash::Outputs::SumoLogic::Common
    STOP_TAG = "PLUGIN STOPPED"

    def initialize(client, queue, stats, config)
      @client = client
      @queue = queue
      @stats = stats

      @url = config["url"]
      @sender_max = (config["sender_max"] ||= 1) < 1 ? 1 : config["sender_max"]
      @sleep_before_requeue = config["sleep_before_requeue"] ||= 30

      @tokens = SizedQueue.new(@sender_max)
      @sender_max.times { |t| @tokens << t }

      @headers = LogStash::Outputs::SumoLogic::HeaderBuilder.new(config).build()
      @compressor = LogStash::Outputs::SumoLogic::Compressor.new(config)

    end # def initialize

    def start()
      @stopping = Concurrent::AtomicBoolean.new(false)

      @sender_t = Thread.new {
        while @stopping.false?
          content = @queue.deq()
          send_request(content)
        end # while
        @queue.drain().map { |content| 
          send_request(content)
        }
        log_info "waiting messages sent out..."
        while @tokens.size < @sender_max
          sleep 1
        end # while
      }
    end # def start_sender

    def stop()
      log_info "shutting down sender..."
      @stopping.make_true()
      @queue.enq(STOP_TAG)
      @sender_t.join
      log_info "sender is fully shutted down"
    end # def stop_sender
    
    def connect()
      uri = URI.parse(@url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = @url.downcase().start_with?("https")
      request = Net::HTTP::Get.new(uri.request_uri)
      begin
        res = http.request(request)
        if res.code.to_i != 200
          log_err(
            "Server rejected the request",
            :url => @url,
            :code => res.code
          )
          false
        else
          log_dbg(
            "Server accepted the request",
            :url => @url
          )
          true
        end
      rescue Exception => ex
        log_err(
          "Cannot connect to given url",
          :url => @url,
          :exception => ex
        )
        false
      end
    end # def connect
    
    private

    def send_request(content)
      if content == STOP_TAG
        log_dbg "STOP_TAG is received."
        return
      end
      
      token = @tokens.pop()
      body = @compressor.compress(content)
  
      request = @client.send(:background).send(:post, @url, :body => body, :headers => @headers)
      
      request.on_complete do
        @tokens << token
      end
  
      request.on_success do |response|
        @stats.record_response_success(response.code)
        if response.code < 200 || response.code > 299
          log_err(
            "HTTP request rejected",
            :token => token,
            :code => response.code,
            :contet => content
          )
          if response.code == 429 || response.code == 503 || response.code == 504
            requeue_message(content)
          end
        else
          log_dbg(
            "HTTP request accepted",
            :token => token,
            :code => response.code)
        end
      end
  
      request.on_failure do |exception|
        @stats.record_response_failure()
        log_err(
          "Error in network transmission",
          :token => token,
          :message => exception.message,
          :class => exception.class.name,
          :backtrace => exception.backtrace
        )
        requeue_message(content)
      end      

      @stats.record_request(content.bytesize, body.bytesize)
      request.call
    end # def send_request

    def requeue_message(content)
      if @stopping.false?
        log_warn(
          "requeue message",
          :after => @sleep_before_requeue,
          :size => content.bytesize)
        Stud.stoppable_sleep(@sleep_before_requeue) { @stopping.true? }
        @queue.enq(content)
      end
    end # def reque_message

  end
end; end; end