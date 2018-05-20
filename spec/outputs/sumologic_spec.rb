# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/outputs/sumologic"
require "logstash/event"

describe LogStash::Outputs::SumoLogic do

  context "configuration" do

    let(:plugin) {
      LogStash::Outputs::SumoLogic.new(
        "url" => "http://localhost/1234",
        "source_category" => "my source category")
    }

    specify {
      puts "#{plugin.config}"
      expect(plugin.params["url"]).to eq("http://localhost/1234")
      expect(plugin.params["source_category"]).to eq("my source category")
    }

  end # context

end # describe
