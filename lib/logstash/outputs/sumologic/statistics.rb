module LogStash; module Outputs; class SumoLogic;
  class Statistics

    require "logstash/outputs/sumologic/common"
    include LogStash::Outputs::SumoLogic::Common

    attr_reader :initialize_time
    attr_reader :total_input_times
    attr_reader :total_input_bytes
    attr_reader :current_pile_size
    attr_reader :total_enqueue_times
    attr_reader :total_enqueue_bytes
    attr_reader :total_dequeue_times
    attr_reader :total_dequeue_bytes
    attr_reader :current_queue_size
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
      @current_pile_size = 0
      @total_enqueue_times = 0
      @total_enqueue_bytes = 0
      @total_dequeue_times = 0
      @total_dequeue_bytes = 0
      @current_queue_size = 0
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
      @total_input_bytes += entry.size
      @current_pile_size += entry.size
    end # def record_input

    def record_clear_pile()
      @current_pile_size = 0
    end # def record_pile_clear

    def record_enqueue(payload)
      @total_enqueue_times += 1
      @total_enqueue_bytes += payload.size
      @current_queue_size += payload.size
    end # def record_enqueue

    def record_dequeue(payload)
      @total_dequeue_times += 1
      @total_dequeue_bytes += payload.size
      @current_queue_size -= payload.size
    end # def record_dequeue

  end
end; end; end