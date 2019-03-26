# encoding: utf-8

module LogStash; module Outputs; class SumoLogic;
  class Sender

    require "net/https"
    require "socket"
    require "thread"
    require "uri"
    require "logstash/outputs/sumologic/common"
    require "logstash/outputs/sumologic/compressor"
    require "logstash/outputs/sumologic/header_builder"
    require "logstash/outputs/sumologic/statistics"
    require "logstash/outputs/sumologic/message_queue"
    include LogStash::Outputs::SumoLogic::Common


    def initialize(client, queue, stats, config)
      @client = client
      @queue = queue
      @stats = stats
      @stopping = Concurrent::AtomicBoolean.new(false)
      @url = config["url"]
      @sender_max = (config["sender_max"] ||= 1) < 1 ? 1 : config["sender_max"]
      @sleep_before_requeue = config["sleep_before_requeue"] ||= 30
      @stats_enabled = config["stats_enabled"] ||= false

      @tokens = SizedQueue.new(@sender_max)
      @sender_max.times { |t| @tokens << t }

      @compressor = LogStash::Outputs::SumoLogic::Compressor.new(config)

    end # def initialize

    def start()
      log_info("starting sender...",
        :max => @sender_max, 
        :requeue => @sleep_before_requeue)
      @stopping.make_false()
      @sender_t = Thread.new {
        while @stopping.false?
          batch = @queue.deq()
          send_request(batch)
        end # while
        @queue.drain().map { |batch| 
          send_request(batch)
        }
        log_info("waiting while senders finishing...")
        while @tokens.size < @sender_max
          sleep 1
        end # while
      }
    end # def start

    def stop()
      log_info("shutting down sender...")
      @stopping.make_true()
      @queue.enq(Batch.new(Hash.new, STOP_TAG))
      @sender_t.join
      log_info("sender is fully shutted down")
    end # def stop
    
    def connect()
      uri = URI.parse(@url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = @url.downcase().start_with?("https")
      request = Net::HTTP::Get.new(uri.request_uri)
      begin
        res = http.request(request)
        if res.code.to_i != 200
          log_err("ping rejected",
            :url => @url,
            :code => res.code,
            :body => res.body)
          false
        else
          log_info("ping accepted",
            :url => @url)
          true
        end
      rescue Exception => exception
        log_err("ping failed",
          :url => @url,
          :message => exception.message,
          :class => exception.class.name,
          :backtrace => exception.backtrace)
        false
      end
    end # def connect
    
    private

    def send_request(batch)
      content = batch.payload
      headers = batch.headers
      if content == STOP_TAG
        log_info("STOP_TAG is received.")
        return
      end
      
      token = @tokens.pop()

      if @stats_enabled && content.start_with?(STATS_TAG)
        body = @compressor.compress(content[STATS_TAG.length..-1])
        headers[CATEGORY_HEADER] = "#{headers[CATEGORY_HEADER]}.stats"
        headers[CONTENT_TYPE] = CONTENT_TYPE_CARBON2
      else
        body = @compressor.compress(content)
      end

      log_dbg("sending request",
        :headers => headers,
        :content_size => content.size,
        :content => content[0..20],
        :payload_size => body.size)
      request = @client.send(:background).send(:post, @url, :body => body, :headers => headers)
      
      request.on_complete do
        @tokens << token
      end
  
      request.on_success do |response|
        @stats.record_response_success(response.code)
        if response.code < 200 || response.code > 299
          log_err("request rejected",
            :token => token,
            :code => response.code,
            :headers => headers,
            :contet => content[0..20])
          if response.code == 429 || response.code == 503 || response.code == 504
            requeue_message(batch)
          end
        else
          log_dbg("request accepted",
            :token => token,
            :code => response.code)
        end
      end
  
      request.on_failure do |exception|
        @stats.record_response_failure()
        log_err("error in network transmission",
          :token => token,
          :message => exception.message,
          :class => exception.class.name,
          :backtrace => exception.backtrace)
        requeue_message(batch)
      end      

      @stats.record_request(content.bytesize, body.bytesize)
      request.call
    end # def send_request

    def requeue_message(batch)
      content = batch.payload
      if @stats_enabled && content.start_with?(STATS_TAG)
        log_warn("do not requeue stats payload",
          :content => content)
      elsif @stopping.false? && @sleep_before_requeue >= 0
        log_info("requeue message",
          :after => @sleep_before_requeue,
          :queue_size => @queue.size,
          :content_size => content.size,
          :content => content[0..20],
          :headers => batch.headers)
        Stud.stoppable_sleep(@sleep_before_requeue) { @stopping.true? }
        @queue.enq(batch)
      end
    end # def reque_message

  end
end; end; end