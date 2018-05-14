# encoding: utf-8

module LogStash; module Outputs; class SumoLogic;
  class Piler

    include LogStash::Outputs::SumoLogic::Common

    attr_reader :is_running
    attr_reader :is_pile

    TEAR_DOWN_TIMEOUT = 10

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
      if (@is_running)
        log_warn "start when piler is running, ignore", {}
      else
        @is_running = true
        if (@is_pile)
          Thread.new { 
            while @is_running
              enq_and_clear()
              Stud.stoppable_sleep(@interval) { !@is_running }
            end # while
          }
        end # if
      end # if
    end # def start

    def stop(timeout = TEAR_DOWN_TIMEOUT, no_warn = false)
      if (!@is_running && !no_warn)
        log_warn "stop when piler is not running, ignore", {}
      else
        @is_running = false
        if (@is_pile)
          teardown_t = Thread.new {
            sleep timeout
            while(!@queue.empty?)
              if (no_warn)
                @queue.deq()
              else
                log_warn("drop message (teardown)", "message" => @queue.deq())
              end
            end
          }
          enq_and_clear()
          teardown_t.join
        end # if
      end # if
    end # def stop

    def input(entry)
      if (!@is_running)
        log_warn "piler is not running, message ignored", "message" => entry
      elsif (@is_pile)
        @semaphore.synchronize {
          if @pile_size + entry.bytesize > @pile_max
            enq(@pile.join($/))
            @pile.clear
            @pile_size = 0
            @stats.record_clear_pile()
          end
          @pile << entry
          @pile_size += entry.bytesize
          @stats.record_input(entry)
        }
      else
        enq(entry)
      end # if
    end # def input

    def enq(payload)
      if (payload.bytesize > 0)
        @queue << payload
        @stats.record_enque(payload)
      end
    end # def enque

    def deq()
      payload = @queue.deq()
      @stats.record_deque(payload)
      payload
    end # def deq

    def drain()
      @queue.size.times.map {
        payload = @queue.deq()
        @stats.record_deque(payload)
      }
    end # def drain

    private
    def enq_and_clear()
      if (@pile.size > 0)
        @semaphore.synchronize {
          if (@pile.size > 0)
            enq(@pile.join($/))
            @pile.clear
            @pile_size = 0
            @stats.record_clear_pile()
          end
        }
      end
    end # def enq_and_clear

  end
end; end; end