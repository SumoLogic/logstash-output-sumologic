# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/outputs/sumologic"
include LogStash::Outputs

describe SumoLogic::MessageQueue do

  context "working in pile mode if interval > 0 && pile_max > 0" do

    let(:queue) { SumoLogic::MessageQueue.new(stats, "queue_max" => 10) }
    let(:stats) { SumoLogic::Statistics.new }

    it "enq() correctly" do
      10.times { |i|
        queue.enq(SumoLogic::Batch.new(Hash.new, "test  -  #{i}"))
        expect(queue.size()).to eq(i + 1)
        expect(stats.total_enque_times.value).to eq(i + 1)
      }
      expect(queue.bytesize()).to eq(100)
    end

    it "deq() correctly" do
      10.times { |i|
        queue.enq(SumoLogic::Batch.new(Hash.new, "test  -  #{i}"))
      }
      10.times { |i|
        expect(queue.size()).to eq(10 - i)
        result = queue.deq()
        expect(result.payload).to eq("test  -  #{i}")
        expect(stats.total_deque_times.value).to eq(i + 1)
      }
      expect(queue.bytesize()).to eq(0)
    end

    it "drain() correctly" do
      10.times { |i|
        queue.enq(SumoLogic::Batch.new(Hash.new, "test  -  #{i}"))
      }
      result = queue.drain()
      expect(queue.size()).to eq(0)
      expect(stats.total_deque_times.value).to eq(10)
      expect(result.size).to eq(10)
      expect(queue.bytesize()).to eq(0)
      10.times { |i|
        expect(result[i].payload).to eq("test  -  #{i}")
      }
    end

  end
end