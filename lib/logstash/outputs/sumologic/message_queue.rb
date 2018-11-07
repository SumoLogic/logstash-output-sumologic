# encoding: utf-8
require "logstash/outputs/sumologic/common"
require "logstash/outputs/sumologic/statistics"

module LogStash; module Outputs; class SumoLogic;
  class MessageQueue

    include LogStash::Outputs::SumoLogic::Common

    def initialize(stats, config)
      @queue_max = (config["queue_max"] ||= 1) < 1 ? 1 : config["queue_max"]
      @queue = SizedQueue::new(@queue_max)
      log_info("initialize memory queue", :max => @queue_max)
      @stats = stats
    end # def initialize

    def enq(obj)
      if (obj.bytesize > 0)
        @queue.enq(obj)
        @stats.record_enque(obj)
        log_dbg("enqueue",
          :objects_in_queue => size,
          :bytes_in_queue => @stats.current_queue_bytes,
          :size => obj.bytesize)
      end
    end # def enq

    def deq()
      obj = @queue.deq()
      @stats.record_deque(obj)
      log_dbg("dequeue",
        :objects_in_queue => size,
        :bytes_in_queue => @stats.current_queue_bytes,
        :size => obj.bytesize)
      obj
    end # def deq

    def drain()
      @queue.size.times.map {
        deq()
      }
    end # def drain

    def size()
      @queue.size()
    end # size
    
  end
end; end; end