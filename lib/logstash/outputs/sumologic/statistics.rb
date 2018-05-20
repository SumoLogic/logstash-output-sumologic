# encoding: utf-8
require "logstash/outputs/sumologic/common"

module LogStash; module Outputs; class SumoLogic;
  class Statistics

    include LogStash::Outputs::SumoLogic::Common

    attr_reader :initialize_time
    attr_reader :total_input_times
    attr_reader :total_input_bytes
    attr_reader :current_pile_items
    attr_reader :current_pile_bytes
    attr_reader :total_enque_times
    attr_reader :total_enque_bytes
    attr_reader :total_deque_times
    attr_reader :total_deque_bytes
    attr_reader :current_queue_items
    attr_reader :current_queue_bytes
    attr_reader :total_request
    attr_reader :total_request_bytes
    attr_reader :total_request_bytes_compressed 
    attr_reader :total_response

    def initialize()
      @initialize_time = Time.now()
      @total_input_times = 0
      @total_input_bytes = 0
      @current_pile_items = 0
      @current_pile_bytes = 0
      @total_enque_times = 0
      @total_enque_bytes = 0
      @total_deque_times = 0
      @total_deque_bytes = 0
      @current_queue_items = 0
      @current_queue_bytes = 0
      @total_request = 0
      @total_request_bytes = 0
      @total_request_bytes_compressed = 0
      @total_response = Hash.new(0)
      @semaphore = Mutex.new
    end # def initialize

    def record_input(entry)
      @total_input_times += 1
      @total_input_bytes += entry.bytesize
      @current_pile_items += 1
      @current_pile_bytes += entry.bytesize
    end # def record_input

    def record_clear_pile()
      @current_pile_items = 0
      @current_pile_bytes = 0
    end # def record_pile_clear

    def record_enque(payload)
      @total_enque_times += 1
      @total_enque_bytes += payload.bytesize
      @current_queue_items += 1
      @current_queue_bytes += payload.bytesize
    end # def record_enque

    def record_deque(payload)
      @total_deque_times += 1
      @total_deque_bytes += payload.bytesize
      @current_queue_items -= 1
      @current_queue_bytes -= payload.bytesize
    end # def record_deque

    @total_payload_bytes = 0
    @total_payload_bytes_compressed = 0

    def record_request(size, size_compressed)
      @total_request += 1
      @total_request_bytes += size
      @total_request_bytes_compressed += size_compressed
    end # def record_request

    def record_response_success(code)
      @semaphore.synchronize {
        now = @total_response[code]
        @total_response[code] = now + 1
      }
    end # def record_response_success

    def record_response_failure()
      @semaphore.synchronize {
        now = @total_response["failure"]
        @total_response["failure"] = now + 1
      }
    end # def record_response_failure

  end
end; end; end