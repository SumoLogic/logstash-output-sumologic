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
    attr_reader :total_payload_bytes
    attr_reader :total_payload_bytes_compressed

    def initialize()
      @initialize_time = Time.now()
      @total_input_times = Concurrent::AtomicFixnum.new
      @total_input_bytes = Concurrent::AtomicFixnum.new
      @current_pile_items = Concurrent::AtomicFixnum.new
      @current_pile_bytes = Concurrent::AtomicFixnum.new
      @total_enque_times = Concurrent::AtomicFixnum.new
      @total_enque_bytes = Concurrent::AtomicFixnum.new
      @total_deque_times = Concurrent::AtomicFixnum.new
      @total_deque_bytes = Concurrent::AtomicFixnum.new
      @current_queue_items = Concurrent::AtomicFixnum.new
      @current_queue_bytes = Concurrent::AtomicFixnum.new
      @total_request = Concurrent::AtomicFixnum.new
      @total_request_bytes = Concurrent::AtomicFixnum.new
      @total_request_bytes_compressed = Concurrent::AtomicFixnum.new
      @total_response = Concurrent::Map.new
      @total_payload_bytes = Concurrent::AtomicFixnum.new
      @total_payload_bytes_compressed = Concurrent::AtomicFixnum.new
  
    end # def initialize

    def total_response(key)
      @total_response.get(key) ? @total_response.get(key).value : 0
    end

    def record_input(entry)
      @total_input_times.increment()
      @total_input_bytes.update { |v| v + entry.bytesize }
      @current_pile_items.increment()
      @current_pile_bytes.update { |v| v + entry.bytesize }
    end # def record_input

    def record_clear_pile()
      @current_pile_items.value= 0
      @current_pile_bytes.value= 0
    end # def record_pile_clear

    def record_enque(payload)
      @total_enque_times.increment()
      @total_enque_bytes.update { |v| v + payload.bytesize }
      @current_queue_items.increment()
      @current_queue_bytes.update { |v| v + payload.bytesize }
    end # def record_enque

    def record_deque(payload)
      @total_deque_times.increment()
      @total_deque_bytes.update { |v| v + payload.bytesize }
      @current_queue_items.decrement()
      @current_queue_bytes.update { |v| v - payload.bytesize }
    end # def record_deque

    def record_request(size, size_compressed)
      @total_request.increment()
      @total_request_bytes.update { |v| v + size }
      @total_request_bytes_compressed.update { |v| v + size_compressed }
    end # def record_request

    def record_response_success(code)
      atomic_map_increase(@total_response, code.to_s)
    end # def record_response_success

    def record_response_failure()
      atomic_map_increase(@total_response, "failure")
    end # def record_response_failure

    def atomic_map_increase(map, key)
      number = map.get(key)
      if number.nil?
        newNumber = Concurrent::AtomicFixnum.new
        number = map.put_if_absent(key, newNumber)
        if number.nil?
          number = newNumber
        end
      end
      number.increment()
    end # def atomic_map_increase

  end
end; end; end