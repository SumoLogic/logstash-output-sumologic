# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/outputs/sumologic/piler"

describe LogStash::Outputs::SumoLogic::Piler do
  
  before :each do
    piler.start()
  end

  after :each do
    queue.drain()
    piler.stop()
  end

  context "working in pile mode if interval > 0 && pile_max > 0" do
    let(:config) { {"queue_max" => 10, "interval" => 10, "pile_max" => 100 } }
    let(:stats) { LogStash::Outputs::SumoLogic::Statistics.new() }
    let(:queue) { LogStash::Outputs::SumoLogic::MessageQueue.new(stats, config) }
    let(:piler) { LogStash::Outputs::SumoLogic::Piler.new(queue, stats, config) }
    specify {
      expect(piler.is_pile).to be true
    }
  end # context

  context "working in non-pile mode if interval <= 0" do
    let(:config) { {"queue_max" => 10, "interval" => 0, "pile_max" => 100 } }
    let(:stats) { LogStash::Outputs::SumoLogic::Statistics.new() }
    let(:queue) { LogStash::Outputs::SumoLogic::MessageQueue.new(stats, config) }
    let(:piler) { LogStash::Outputs::SumoLogic::Piler.new(queue, stats, config) }
    specify {
      expect(piler.is_pile).to be false
    }
  end # context

  context "working in non-pile mode if pile_max <= 0" do
    let(:config) { {"queue_max" => 10, "interval" => 10, "pile_max" => 0 } }
    let(:stats) { LogStash::Outputs::SumoLogic::Statistics.new() }
    let(:queue) { LogStash::Outputs::SumoLogic::MessageQueue.new(stats, config) }
    let(:piler) { LogStash::Outputs::SumoLogic::Piler.new(queue, stats, config) }
    specify {
      expect(piler.is_pile).to be false
    }
  end # context

  context "in non-pile mode" do

    let(:config) { {"queue_max" => 10, "interval" => 0, "pile_max" => 100 } }
    let(:stats) { LogStash::Outputs::SumoLogic::Statistics.new() }
    let(:queue) { LogStash::Outputs::SumoLogic::MessageQueue.new(stats, config) }
    let(:piler) { LogStash::Outputs::SumoLogic::Piler.new(queue, stats, config) }

    it "enque immediately after input" do
      expect(stats.current_pile_items).to be 0
      expect(stats.current_queue_items).to be 0
      piler.input("This is a log line")
      expect(stats.current_pile_items).to be 0
      expect(stats.current_queue_items).to be 1
      expect(stats.current_queue_bytes).to be 18
    end

    it "deque correctly" do
      expect(stats.current_queue_items).to be 0
      expect(stats.total_enque_times).to be 0
      piler.input("This is a log line")
      expect(stats.total_enque_times).to be 1
      expect(stats.current_queue_items).to be 1
      expect(stats.current_queue_bytes).to be 18
      expect(stats.total_deque_times).to be 0
      expect(queue.deq()).to eq "This is a log line"
      expect(stats.current_queue_items).to be 0
      expect(stats.current_queue_bytes).to be 0
      expect(stats.total_deque_times).to be 1
    end

  end # context

  context "in pile mode" do

    let(:config) { {"queue_max" => 10, "interval" => 5, "pile_max" => 25 } }
    let(:stats) { LogStash::Outputs::SumoLogic::Statistics.new() }
    let(:queue) { LogStash::Outputs::SumoLogic::MessageQueue.new(stats, config) }
    let(:piler) { LogStash::Outputs::SumoLogic::Piler.new(queue, stats, config) }

    it "wait in pile before size reach pile_max" do
      expect(stats.current_pile_items).to be 0
      expect(stats.current_pile_bytes).to be 0
      expect(stats.current_queue_items).to be 0
      piler.input("1234567890")
      expect(stats.current_pile_items).to be 1
      expect(stats.current_pile_bytes).to be 10
      expect(stats.current_queue_items).to be 0
      piler.input("1234567890")
      expect(stats.current_pile_items).to be 2
      expect(stats.current_pile_bytes).to be 20
      expect(stats.current_queue_items).to be 0
    end

    it "enqueue content from pile when reach pile_max" do
      expect(stats.current_pile_items).to be 0
      expect(stats.current_pile_bytes).to be 0
      expect(stats.current_queue_items).to be 0
      piler.input("1234567890")
      piler.input("1234567890")
      expect(stats.current_queue_items).to be 0
      piler.input("1234567890")
      expect(stats.current_pile_items).to be 1
      expect(stats.current_pile_bytes).to be 10
      expect(stats.current_queue_items).to be 1
      expect(stats.current_queue_bytes).to be 21
    end

    it "enqueue content from pile when reach interval" do
      expect(stats.current_pile_items).to be 0
      expect(stats.current_pile_bytes).to be 0
      piler.input("1234567890")
      piler.input("1234567890")
      expect(stats.current_queue_items).to be 0
      sleep(8)
      expect(stats.current_pile_items).to be 0
      expect(stats.current_pile_bytes).to be 0
      expect(stats.current_queue_items).to be 1
      expect(stats.current_queue_bytes).to be 21
    end

  end # context

  context "pile to message queue" do

    let(:config) { {"queue_max" => 5, "interval" => 500, "pile_max" => 5} }
    let(:stats) { LogStash::Outputs::SumoLogic::Statistics.new() }
    let(:queue) { LogStash::Outputs::SumoLogic::MessageQueue.new(stats, config) }
    let(:piler) { LogStash::Outputs::SumoLogic::Piler.new(queue, stats, config) }

    it "enqueue payloads from pile before reach queue_max" do
      expect(stats.current_queue_items).to be 0
      piler.input("1234567890")
      expect(stats.current_queue_items).to be 0
      expect(stats.current_queue_bytes).to be 0
      piler.input("2234567890")
      expect(stats.current_queue_items).to be 1
      expect(stats.current_queue_bytes).to be 10
      piler.input("3234567890")
      expect(stats.current_queue_items).to be 2
      expect(stats.current_queue_bytes).to be 20
    end

    it "block input thread if queue is full" do
      input_t = Thread.new {
        for i in 0..9 do
          piler.input("#{i}234567890")
        end
      }
      sleep(3)
      expect(stats.current_queue_items).to be 5
      expect(stats.current_queue_bytes).to be 50
      queue.drain()
      piler.stop()
      input_t.join
      expect(stats.total_deque_times).to be 5
      expect(stats.total_deque_bytes).to be 50
    end

    it "resume input thread if queue is drained" do
      input_t = Thread.new {
        for i in 0..9 do
          piler.input("#{i}234567890")
        end
      }
      sleep(3)
      expect(stats.total_deque_times).to be 0
      expect(stats.total_enque_times).to be 5
      queue.deq()
      sleep(1)
      expect(stats.total_deque_times).to be 1
      expect(stats.total_enque_times).to be 6
      queue.deq()
      sleep(1)
      expect(stats.total_deque_times).to be 2
      expect(stats.total_enque_times).to be 7
      queue.drain()
      piler.stop()
      input_t.join
    end

  end # context

end # describe

