# encoding: utf-8
require "logstash/outputs/sumologic/common"
require "logstash/outputs/sumologic/statistics"
require "logstash/outputs/sumologic/message_queue"

module LogStash; module Outputs; class SumoLogic;
  class Monitor

    include LogStash::Outputs::SumoLogic::Common

    attr_reader :is_pile

    def initialize(queue, stats, config)
      @queue = queue
      @stats = stats
      @stopping = Concurrent::AtomicBoolean.new(false)

      @enabled = config["stats_enabled"] ||= false
      @interval = config["stats_interval"] ||= 60
      @interval = @interval < 0 ? 0 : @interval
      @last = Hash.new(0)
    end # initialize

    def start()
      @stopping.make_false()
      if (@enabled)
        @monitor_t = Thread.new { 
          while @stopping.false?
            Stud.stoppable_sleep(@interval) { @stopping.true? }
            if @stats.total_input_events.value > 0
              @queue.enq(build_stats_payload())
            end
          end # while
        }
      end # if
    end # def start

    def stop()
      @stopping.make_true()
      if (@enabled)
        log_info "shutting down monitor..."
        @monitor_t.join
        log_info "monitor is fully shutted down"
      end
    end # def stop

    def build_stats_payload()
      timestamp = Time.now().to_i
      
      counters = [
        "total_input_events", 
        "total_input_bytes", 
        "total_metrics_datapoints", 
        "total_log_lines", 
        "total_output_requests",
        "total_output_bytes",
        "total_output_bytes_compressed"
      ].map { |key|
        diff = diff_value(key)
        build_metric_line(key[6..-1], diff, timestamp)
      }.join($/)
      
      rate = build_response_success_rate(timestamp)
      
      "#{STATS_TAG}#{counters}\n#{rate}"
    end # def build_stats_payload

    def build_response_success_rate(timestamp)
      success_diff = diff_value("total_response_success")
      total_diff = diff_value("total_response_times")
      percentage = success_diff * 1.0 / total_diff
      build_metric_line("response_success_rate", percentage, timestamp)
    end # def build_response_success_rate

    def build_metric_line(key, value, timestamp)
      "metric=#{key} interval=#{@interval}  category=monitor #{value} #{timestamp}"
    end # def build_metric_line

    def diff_value(key)
      newValue = @stats.send(key).value
      diff = newValue - @last[key]
      @last.store(key, newValue)
      diff
    end # def diff_value

  end
end; end; end        
