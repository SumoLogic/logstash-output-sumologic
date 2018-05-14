# encoding: utf-8
require "net/https"
require "socket"
require "stringio"
require 'thread'
require "uri"
require "zlib"

module LogStash; module Outputs; class SumoLogic;
  module Sender

    include LogStash::Outputs::SumoLogic::Common

    @@sender_running = false

    def start_sender()
      @@sender_running = true
      @@request_tokens = SizedQueue.new(@sender_max)
      @sender_max.times { |t| @@request_tokens << t }
      @@headers = build_header()

      @@sender_t = Thread.new { 
        while @@sender_running
          content = @piler.deq()
          send_request(content)
        end # while
        @piler.drain().map { |content| 
          send_request(content)
        }
      }
    end # def start_sender

    def stop_sender()
      @@sender_running = false
      @@sender_t.join
      client.close()
    end # def stop_sender
    
    def connect(use_ssl = true)
      uri = URI.parse(@url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = use_ssl
      request = Net::HTTP::Get.new(uri.request_uri)
      begin
        res = http.request(request)
        if res.code.to_i != 200
          log_err(
            "Server did not accept request",
            :url => @url,
            :code => res.code
          )
          false
        else
          log_dbg(
            "Server ping success",
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
      token = @@request_tokens.pop()
      body = compress(content)
  
      request = client.send(:background).send(:post, @url, :body => body, :headers => @@headers)
      
      request.on_complete do
        @@request_tokens << token
      end
  
      request.on_success do |response|
        @stats.record_request_success(response.code)
        if response.code < 200 || response.code > 299
          log_err(
            "HTTP request rejected",
            :token => token,
            :code => response.code)
          @piler.enq(content)
        else
          log_dbg(
            "HTTP request accepted",
            :token => token,
            :code => response.code)
        end
      end
  
      request.on_failure do |exception|
        log_err(
          "Error in network transmission",
          :token => token,
          :message => exception.message,
          :class => exception.class.name,
          :backtrace => exception.backtrace
        )
        @piler.enq(content)
      end      

      @stats.record_request(content.bytesize, body.bytesize)
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
  
  end
end; end; end