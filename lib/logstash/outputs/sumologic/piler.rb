# encoding: utf-8

module LogStash; module Outputs; class SumoLogic;
  class Piler

    require "logstash/outputs/sumologic/common"
    require "logstash/outputs/sumologic/statistics"
    require "logstash/outputs/sumologic/message_queue"
    include LogStash::Outputs::SumoLogic::Common

    attr_reader :is_pile

    def initialize(queue, stats, config)
      
      @interval = config["interval"] ||= 0
      @pile_max = config["pile_max"] ||= 0
      @queue = queue
      @stats = stats
      @stopping = Concurrent::AtomicBoolean.new(false)
      @payload_builder = PayloadBuilder.new(@stats, config)
      @header_builder = HeaderBuilder.new(config)
      @is_pile = (@interval > 0 && @pile_max > 0)
      if (@is_pile)
        @pile = Hash.new("")
        @semaphore = Mutex.new
      end
  
    end # def initialize

    def start()
      @stopping.make_false()
      if (@is_pile)
        log_info("starting piler...", 
          :max => @pile_max, 
          :timeout => @interval)
        @piler_t = Thread.new { 
          while @stopping.false?
            Stud.stoppable_sleep(@interval) { @stopping.true? }
            log_dbg("timeout", :timeout => @interval)
            enq_and_clear()
          end # while
        }
      end # if
    end # def start

    def stop()
      @stopping.make_true()
      if (@is_pile)
        log_info("shutting down piler in #{@interval * 2} secs ...")
        @piler_t.join(@interval * 2)
        log_info("piler is fully shutted down")
      end
    end # def stop

    def input(event)
      if (@stopping.true?)
        log_warn("piler is shutting down, event is dropped", 
          "event" => event)
      else
        headers = @header_builder.build(event)
        payload = @payload_builder.build(event)
        if (@is_pile)
          @semaphore.synchronize {
            content = @pile[headers]
            size = content.bytesize
            if size + payload.bytesize > @pile_max
              @queue.enq(Batch.new(headers, content))
              @pile[headers] = ""
            end
            @pile[headers] = @pile[headers].blank? ? payload : "#{@pile[headers]}\n#{payload}"
          }
        else
          @queue.enq(Batch.new(headers, payload))
        end # if
      end
    end # def input

    private
    def enq_and_clear()
      @semaphore.synchronize {
        @pile.each do |headers, content|
          @queue.enq(Batch.new(headers, content))
        end
        @pile.clear()
      }
    end # def enq_and_clear

  end
end; end; end