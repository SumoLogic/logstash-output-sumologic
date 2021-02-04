# encoding: utf-8

module LogStash; module Outputs; class SumoLogic;
  class Monitor

    require "logstash/outputs/sumologic/common"
    require "logstash/outputs/sumologic/statistics"
    require "logstash/outputs/sumologic/message_queue"
    include LogStash::Outputs::SumoLogic::Common

    attr_reader :is_pile

    def initialize(queue, stats, config)
      @queue = queue
      @stats = stats
      @stopping = Concurrent::AtomicBoolean.new(false)
      @header_builder = HeaderBuilder.new(config)

      @enabled = config["stats_enabled"] ||= false
      @interval = config["stats_interval"] ||= 60
      @interval = @interval < 0 ? 0 : @interval
    end # initialize

    def start()
      log_info("starting monitor...", :interval => @interval)
      @stopping.make_false()
      if (@enabled)
        @monitor_t = Thread.new { 
          while @stopping.false?
            Stud.stoppable_sleep(@interval) { @stopping.true? }
            if @stats.total_log_lines.value > 0 || @stats.total_metrics_datapoints.value > 0
              @queue.enq(Batch.new(headers(), build_stats_payload()))
            end
          end # while
        }
      end # if
    end # def start

    def stop()
      @stopping.make_true()
      if (@enabled)
        log_info("shutting down monitor...")
        @monitor_t.join
        log_info("monitor is fully shutted down")
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
        "total_output_bytes_compressed",
        "total_response_times",
        "total_response_success"
      ].map { |key|
        value = @stats.send(key).value
        log_dbg("stats",
          :key => key,
          :value => value)
        build_metric_line(key, value, timestamp)
      }.join($/)

      "#{STATS_TAG}#{counters}"
    end # def build_stats_payload

    def build_metric_line(key, value, timestamp)
      "metric=#{key} interval=#{@interval}  category=monitor #{value} #{timestamp}"
    end # def build_metric_line

    def headers()
      @headers ||= @header_builder.build_stats()
    end

  end
end; end; end
