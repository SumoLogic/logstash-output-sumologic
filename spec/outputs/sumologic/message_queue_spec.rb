# encoding: utf-8
require "logstash/outputs/sumologic/common"
require "logstash/outputs/sumologic/statistics"
require "logstash/outputs/sumologic/message_queue"

describe LogStash::Outputs::SumoLogic::MessageQueue do
  
  context "working in pile mode if interval > 0 && pile_max > 0" do

    let(:stats) { LogStash::Outputs::SumoLogic::Statistics.new() }

    it "enq() correctly" do
      queue = LogStash::Outputs::SumoLogic::MessageQueue.new(10, stats)
      10.times { |i|
        queue.enq("test - #{i}")
        expect(queue.size()).to eq(i + 1)
        expect(stats.total_enque_times).to eq(i + 1)
      }
    end

    it "deq() correctly" do
      queue = LogStash::Outputs::SumoLogic::MessageQueue.new(10, stats)
      10.times { |i|
        queue.enq("test - #{i}")
      }
      10.times { |i|
        expect(queue.size()).to eq(10 - i)
        result = queue.deq()
        expect(result).to eq("test - #{i}")
        expect(stats.total_deque_times).to eq(i + 1)
      }
    end

    it "drain() correctly" do
      queue = LogStash::Outputs::SumoLogic::MessageQueue.new(10, stats)
      10.times { |i|
        queue.enq("test - #{i}")
      }
      result = queue.drain()
      expect(queue.size()).to eq(0)
      expect(stats.total_deque_times).to eq(10)
      expect(result.size).to eq(10)
      10.times { |i|
        expect(result[i]).to eq("test - #{i}")
      }
    end

  end
end