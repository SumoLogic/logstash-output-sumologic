# encoding: utf-8
module LogStash; module Outputs; class SumoLogic;
  class MessageQueue

    require "logstash/outputs/sumologic/common"
    require "logstash/outputs/sumologic/statistics"
    include LogStash::Outputs::SumoLogic::Common

    def initialize(stats, config)
      @queue_max = (config["queue_max"] ||= 1) < 1 ? 1 : config["queue_max"]
      @queue = SizedQueue::new(@queue_max)
      log_info("initialize memory queue", :max => @queue_max)
      @queue_bytesize = Concurrent::AtomicFixnum.new
      @stats = stats
    end # def initialize

    def enq(batch)
      batch_size = batch.payload.bytesize
      if (batch_size > 0)
        @queue.enq(batch)
        @stats.record_enque(batch_size)
        @queue_bytesize.update { |v| v + batch_size }
        log_dbg("enqueue",
          :objects_in_queue => size,
          :bytes_in_queue => @queue_bytesize,
          :size => batch_size)
        end
    end # def enq

    def deq(non_block: false)
      batch = @queue.deq(non_block: non_block)
      batch_size = batch.payload.bytesize
      @stats.record_deque(batch_size)
      @queue_bytesize.update { |v| v - batch_size }
      log_dbg("dequeue",
        :objects_in_queue => size,
        :bytes_in_queue => @queue_bytesize,
        :size => batch_size)
      batch
    end # def deq

    def drain()
      @queue.size.times.map {
        deq()
      }
    end # def drain

    def size()
      @queue.size()
    end # size

    def bytesize()
      @queue_bytesize.value
    end # bytesize
    
  end
end; end; end