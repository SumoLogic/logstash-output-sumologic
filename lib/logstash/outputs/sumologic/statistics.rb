module LogStash; module Outputs; class SumoLogic;
  class Statistics

    require "logstash/outputs/sumologic/common"
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
    attr_reader :total_sent_times
    attr_reader :total_sent_entries
    attr_reader :total_payload_bytes
    attr_reader :total_payload_bytes_compressed
    attr_reader :total_response
    attr_reader :total_response_200
    attr_reader :total_response_419
    attr_reader :total_response_4xx
    attr_reader :total_response_504
    attr_reader :total_response_5xx

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
      @total_sent_times = 0
      @total_sent_entries = 0
      @total_payload_bytes = 0
      @total_payload_bytes_compressed = 0
      @total_response = 0
      @total_response_200 = 0
      @total_response_419 = 0
      @total_response_4xx = 0
      @total_response_504 = 0
      @total_response_5xx = 0
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

  end
end; end; end