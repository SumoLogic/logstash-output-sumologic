# encoding: utf-8

require_relative './common'
require_relative './statistics'
require_relative './message_queue'

module LogStash; module Outputs; class SumoLogic;
  class Piler

    include LogStash::Outputs::SumoLogic::Common

    attr_reader :is_pile

    TEAR_DOWN_TIMEOUT = 10

    def initialize(config, stats, queue)
      
      @interval = config['interval']
      @pile_max = config['pile_max']
      @stats = stats
      @queue = queue

      @is_pile = (@interval > 0 && @pile_max > 0)

      if (@is_pile)
        @pile = Array.new
        @pile_size = 0
        @semaphore = Mutex.new
        @stopping = Concurrent::AtomicBoolean.new(false)
      end

    end # def initialize

    def start()
      if (@is_pile)
        @piler_t = Thread.new { 
          while !@stopping
            Stud.stoppable_sleep(@interval) { @stopping }
            log_dbg "timeout, enqueue pile now"
            enq_and_clear()
          end # while
        }
      end # if
    end # def start

    def stop()
      log_info "piler is shutting down..."
      @stopping = true
      @piler_t.join
      log_info "piler is fully shut down"
    end # def stop

    def input(entry)
      if (@stopping)
        log_warn "piler is shutting down, message ignored", "message" => entry
      elsif (@is_pile)
        @semaphore.synchronize {
          if @pile_size + entry.bytesize > @pile_max
            @queue.enq(@pile.join($/))
            @pile.clear
            @pile_size = 0
            @stats.record_clear_pile()
          end
          @pile << entry
          @pile_size += entry.bytesize
          @stats.record_input(entry)
        }
      else
        @queue.enq(entry)
      end # if
    end # def input

    private
    def enq_and_clear()
      if (@pile.size > 0)
        @semaphore.synchronize {
          if (@pile.size > 0)
            @queue.enq(@pile.join($/))
            @pile.clear
            @pile_size = 0
            @stats.record_clear_pile()
          end
        }
      end
    end # def enq_and_clear

  end
end; end; end