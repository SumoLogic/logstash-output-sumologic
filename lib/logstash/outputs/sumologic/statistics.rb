# encoding: utf-8

module LogStash; module Outputs; class SumoLogic;
  class Statistics

    require "logstash/outputs/sumologic/common"
    include LogStash::Outputs::SumoLogic::Common

    attr_reader :initialize_time
    attr_reader :total_input_events
    attr_reader :total_input_bytes
    attr_reader :total_metrics_datapoints
    attr_reader :total_log_lines
    attr_reader :total_enque_times
    attr_reader :total_enque_bytes
    attr_reader :total_deque_times
    attr_reader :total_deque_bytes
    attr_reader :total_output_requests
    attr_reader :total_output_bytes
    attr_reader :total_output_bytes_compressed 
    attr_reader :total_response
    attr_reader :total_response_times
    attr_reader :total_response_success

    def initialize()
      @initialize_time = Time.now()
      @total_input_events = Concurrent::AtomicFixnum.new
      @total_input_bytes = Concurrent::AtomicFixnum.new
      @total_metrics_datapoints = Concurrent::AtomicFixnum.new
      @total_log_lines = Concurrent::AtomicFixnum.new
      @total_enque_times = Concurrent::AtomicFixnum.new
      @total_enque_bytes = Concurrent::AtomicFixnum.new
      @total_deque_times = Concurrent::AtomicFixnum.new
      @total_deque_bytes = Concurrent::AtomicFixnum.new
      @total_output_requests = Concurrent::AtomicFixnum.new
      @total_output_bytes = Concurrent::AtomicFixnum.new
      @total_output_bytes_compressed = Concurrent::AtomicFixnum.new
      @total_response = Concurrent::Map.new
      @total_response_times = Concurrent::AtomicFixnum.new
      @total_response_success = Concurrent::AtomicFixnum.new
  
    end # def initialize

    def total_response(key)
      @total_response.get(key) ? @total_response.get(key).value : 0
    end

    def record_input(size)
      @total_input_events.increment()
      @total_input_bytes.update { |v| v + size }
    end # def record_input

    def record_log_process()
      @total_log_lines.increment()
    end # def record_log_process

    def record_metrics_process(dps)
      @total_metrics_datapoints.update { |v| v + dps }
    end # def record_metrics_process

    def record_enque(size)
      @total_enque_times.increment()
      @total_enque_bytes.update { |v| v + size }
    end # def record_enque

    def record_deque(size)
      @total_deque_times.increment()
      @total_deque_bytes.update { |v| v + size }
    end # def record_deque

    def record_request(size, size_compressed)
      @total_output_requests.increment()
      @total_output_bytes.update { |v| v + size }
      @total_output_bytes_compressed.update { |v| v + size_compressed }
    end # def record_request

    def record_response_success(code)
      atomic_map_increase(@total_response, code.to_s)
      @total_response_success.increment() if code == 200
      @total_response_times.increment()
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