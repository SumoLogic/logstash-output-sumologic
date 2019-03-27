# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/outputs/sumologic"
include LogStash::Outputs

describe SumoLogic::Piler do
  
  event = LogStash::Event.new("foo" => "bar", "message" => "This is a log line")
  event_10 = LogStash::Event.new("foo" => "bar", "message" => "1234567890")

  before :each do
    piler.start()
  end

  after :each do
    queue.drain()
    piler.stop()
  end

  context "working in pile mode if interval > 0 && pile_max > 0" do
    let(:config) { {"queue_max" => 10, "interval" => 10, "pile_max" => 100 } }
    let(:stats) { SumoLogic::Statistics.new }
    let(:queue) { SumoLogic::MessageQueue.new(stats, config) }
    let(:piler) { SumoLogic::Piler.new(queue, stats, config) }
    specify {
      expect(piler.is_pile).to be true
    }
  end # context

  context "working in non-pile mode if interval <= 0" do
    let(:config) { {"queue_max" => 10, "interval" => 0, "pile_max" => 100 } }
    let(:stats) { SumoLogic::Statistics.new }
    let(:queue) { SumoLogic::MessageQueue.new(stats, config) }
    let(:piler) { SumoLogic::Piler.new(queue, stats, config) }
    specify {
      expect(piler.is_pile).to be false
    }
  end # context

  context "working in non-pile mode if pile_max <= 0" do
    let(:config) { {"queue_max" => 10, "interval" => 10, "pile_max" => 0 } }
    let(:stats) { SumoLogic::Statistics.new }
    let(:queue) { SumoLogic::MessageQueue.new(stats, config) }
    let(:piler) { SumoLogic::Piler.new(queue, stats, config) }
    specify {
      expect(piler.is_pile).to be false
    }
  end # context

  context "in non-pile mode" do
    let(:config) { {"queue_max" => 10, "interval" => 0, "pile_max" => 100, "format" => "%{message}" } }
    let(:stats) { SumoLogic::Statistics.new }
    let(:queue) { SumoLogic::MessageQueue.new(stats, config) }
    let(:piler) { SumoLogic::Piler.new(queue, stats, config) }

    it "enque immediately after input" do
      expect(stats.total_enque_times.value).to be 0
      expect(queue.size).to be 0
      piler.input(event)
      expect(stats.total_enque_times.value).to be 1
      expect(stats.total_enque_bytes.value).to be 18
      expect(queue.size).to be 1
      expect(queue.bytesize).to be 18
    end

    it "deque correctly" do
      piler.input(event)
      expect(queue.deq().payload).to eq "This is a log line"
      expect(queue.size).to be 0
      expect(queue.bytesize).to be 0
      expect(stats.total_deque_times.value).to be 1
      expect(stats.total_deque_bytes.value).to be 18
    end

  end # context

  context "in pile mode" do

    let(:config) { {"queue_max" => 10, "interval" => 5, "pile_max" => 25, "format" => "%{message}" } }
    let(:stats) { SumoLogic::Statistics.new }
    let(:queue) { SumoLogic::MessageQueue.new(stats, config) }
    let(:piler) { SumoLogic::Piler.new(queue, stats, config) }

    it "enqueue content from pile when reach pile_max" do
      expect(queue.size).to be 0
      piler.input(event_10)
      expect(queue.size).to be 0
      piler.input(event_10)
      expect(queue.size).to be 0
      piler.input(event_10)
      expect(queue.size).to be 1
    end

    it "enqueue content from pile when reach interval" do
      expect(queue.size).to be 0
      piler.input(event_10)
      expect(queue.size).to be 0
      piler.input(event_10)
      sleep(10)
      expect(queue.size).to be 1
    end

  end # context

  context "pile to message queue" do

    let(:config) { {"queue_max" => 5, "interval" => 3, "pile_max" => 5, "format" => "%{message}"} }
    let(:stats) { SumoLogic::Statistics.new }
    let(:queue) { SumoLogic::MessageQueue.new(stats, config) }
    let(:piler) { SumoLogic::Piler.new(queue, stats, config) }

    it "block input thread if queue is full" do
      input_t = Thread.new {
        for i in 0..10 do
          piler.input(event_10)
        end
      }
      sleep(3)
      expect(queue.size).to be 5
      expect(queue.bytesize).to be 50
      piler.stop()
      queue.drain()
      input_t.kill()
    end

    it "resume input thread if queue is drained" do
      input_t = Thread.new {
        for i in 0..10 do
          piler.input(event_10)
        end
      }
      sleep(5)
      expect(stats.total_deque_times.value).to be 0
      expect(queue.size).to be 5
      expect(stats.total_enque_times.value).to be 5
      queue.deq()
      sleep(3)
      expect(stats.total_deque_times.value).to be 1
      expect(queue.size).to be 5
      expect(stats.total_enque_times.value).to be 6
      queue.deq()
      sleep(3)
      expect(stats.total_deque_times.value).to be 2
      expect(queue.size).to be 5
      expect(stats.total_enque_times.value).to be 7
      piler.stop()
      queue.drain()
      input_t.kill()
    end

  end # context

end # describe

