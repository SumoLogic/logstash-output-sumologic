module LogStash; module Outputs; class SumoLogic;
  class Piler

    require "logstash/outputs/sumologic/common"
    include LogStash::Outputs::SumoLogic::Common

    attr_reader :is_running
    attr_reader :is_pile

    def initialize(interval, pile_max, queue_max, stats)
      @interval = interval
      @pile_max = pile_max
      @queue_max = queue_max
      @stats = stats

      @pile = Array.new
      @pile_size = 0
      @semaphore = Mutex.new
      @queue = SizedQueue.new(@queue_max)
      @is_running = false
      @is_pile = (@interval > 0 && @pile_max > 0)
    end # def initialize

    def start()
      if (@is_pile)
        @is_running = true
        Thread.new { 
          while @is_running
            enq_and_clear()
            Stud.stoppable_sleep(@interval) { !@is_running }
          end # while
        }
      end # if
    end # def start

    def stop()
      if (@is_pile)
        @is_running = false
        enq_and_clear()
      end # if
    end # def stop

    def input(entry)
      @semaphore.synchronize {
        if (@is_pile)
          if @pile_size + entry.bytesize > @pile_max
            enq_and_clear()
          end
          @pile << entry
          @pile_size += content.bytesize
          @stats.record_input(entry)
        else
          enq(entry)
        end # if
      }
    end # def input

    def enq(payload)
      @queue << payload
      @stats.record_enque(payload)
    end # def enque

    def deq()
      payload = @queue.deq()
      @stats.record_deque(payload)
      payload
    end # def deq
    
    private
    def enq_and_clear()
      if (@pile.size > 0)
        enq(pile.join($/))
        @pile = Array.new
        @pile_size = 0
        @stats.record_clear_pile()
      end
    end # def enq_and_clear

  end
end; end; end