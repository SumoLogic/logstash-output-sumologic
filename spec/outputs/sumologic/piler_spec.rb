# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/outputs/sumologic"

describe LogStash::Outputs::SumoLogic::Piler do
  
  before :each do
    piler.start()
  end

  after :each do
    piler.stop()
  end

  context "working in pile mode if interval > 0 && pile_max > 0" do

    let(:stats) { LogStash::Outputs::SumoLogic::Statistics.new() }
    let(:piler) { LogStash::Outputs::SumoLogic::Piler.new(10, 100, 10, stats) }

    specify {
      expect(piler.is_running).to be true
      expect(piler.is_pile).to be true
    }

  end # context

  context "working in non-pile mode if interval <= 0" do

    let(:stats) { LogStash::Outputs::SumoLogic::Statistics.new() }
    let(:piler) { LogStash::Outputs::SumoLogic::Piler.new(0, 100, 10, stats) }

    specify {
      expect(piler.is_running).to be false
      expect(piler.is_pile).to be false
    }

  end # context

  context "working in non-pile mode if pile_max <= 0" do

    let(:stats) { LogStash::Outputs::SumoLogic::Statistics.new() }
    let(:piler) { LogStash::Outputs::SumoLogic::Piler.new(10, 0, 10, stats) }

    specify {
      expect(piler.is_running).to be false
      expect(piler.is_pile).to be false
    }

  end # context

end # describe

