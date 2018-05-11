# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/outputs/sumologic"
require "logstash/event"

describe LogStash::Outputs::SumoLogic::HeaderBuilder do

  result = {}

  before :each do
    result = plugin.build_header()
  end

  context "shlould build headers by default" do
    let(:plugin) { LogStash::Outputs::SumoLogic.new("url" => "http://localhost/1234") }

    specify {
      expected = {
        "X-Sumo-Client" => "logstash-output-sumologic",
        "X-Sumo-Name" => "logstash-output-sumologic",
        "X-Sumo-Host" => Socket.gethostname,
        "X-Sumo-Category" => "Logstash",
        "Content-Type" => "text/plain"
      }
      expect(result).to eq(expected)
    }

  end # context

  context "should override source_category" do
    
    let(:plugin) {
      LogStash::Outputs::SumoLogic.new(
        "url" => "http://localhost/1234",
        "source_category" => "my source category")
    }

    specify {
      expect(result.count).to eq(5)
      expect(result["X-Sumo-Category"]).to eq("my source category")
    }

  end # context

  context "should override source_name" do
    
    let(:plugin) {
      LogStash::Outputs::SumoLogic.new(
        "url" => "http://localhost/1234",
        "source_name" => "my source name")
    }

    specify {
      expect(result.count).to eq(5)
      expect(result["X-Sumo-Name"]).to eq("my source name")
    }

  end # context

  context "should override source_host" do
    
    let(:plugin) {
      LogStash::Outputs::SumoLogic.new(
        "url" => "http://localhost/1234",
        "source_host" => "my source host")
    }

    specify {
      expect(result.count).to eq(5)
      expect(result["X-Sumo-Host"]).to eq("my source host")
    }

  end # context

  context "should hornor extra_headers" do
    
    let(:plugin) {
      LogStash::Outputs::SumoLogic.new(
        "url" => "http://localhost/1234",
        "extra_headers" => {
          "foo" => "bar"
        })
    }

    specify {
      expect(result.count).to eq(6)
      expect(result["foo"]).to eq("bar")
    }

  end # context

  context "should hornor extra_headers but never overwrite pre-defined headers" do
    
    let(:plugin) {
      LogStash::Outputs::SumoLogic.new(
        "url" => "http://localhost/1234",
        "extra_headers" => {
          "foo" => "bar",
          "X-Sumo-Client" => "a",
          "X-Sumo-Name" => "b",
          "X-Sumo-Host" => "c",
          "X-Sumo-Category" => "d",
          "Content-Type" => "e"
      })
    }

    specify {
      expected = {
        "foo" => "bar",
        "X-Sumo-Client" => "logstash-output-sumologic",
        "X-Sumo-Name" => "logstash-output-sumologic",
        "X-Sumo-Host" => Socket.gethostname,
        "X-Sumo-Category" => "Logstash",
        "Content-Type" => "text/plain"
      }
      expect(result).to eq(expected)
    }

  end # context

  context "should set content type correctly for log payload" do

    let(:plugin) {
      LogStash::Outputs::SumoLogic.new("url" => "http://localhost/1234")
    }

    specify {
      expect(result["Content-Type"]).to eq("text/plain")
    }

  end # context

  context "should set content type correctly for metrics payload (CarbonV2)" do

    let(:plugin) {
      LogStash::Outputs::SumoLogic.new(
        "url" => "http://localhost/1234",
        "fields_as_metrics" => true)
    }

    specify {
      expect(result["Content-Type"]).to eq("application/vnd.sumologic.carbon2")
    }

  end # context

  context "should set content type correctly for metrics payload (Graphite)" do

    let(:plugin) {
      LogStash::Outputs::SumoLogic.new(
        "url" => "http://localhost/1234",
        "metrics_format" => "graphite",
        "fields_as_metrics" => true)
    }

    specify {
      expect(result["Content-Type"]).to eq("application/vnd.sumologic.graphite")
    }

  end # context

  context "should set content encoding correctly for uncompressed payload" do

    let(:plugin) {
      LogStash::Outputs::SumoLogic.new("url" => "http://localhost/1234")
    }

    specify {
      expect(result["Content-Encoding"]).to be_nil
    }

  end # context

  context "should set content encoding correctly for compressed payload (deflate)" do

    let(:plugin) {
      LogStash::Outputs::SumoLogic.new("url" => "http://localhost/1234", "compress" => true)
    }

    specify {
      expect(result["Content-Encoding"]).to eq("deflate")
    }

  end # context

  context "should set content encoding correctly for compressed payload (gzip)" do

    let(:plugin) {
      LogStash::Outputs::SumoLogic.new("url" => "http://localhost/1234", "compress" => true, "compress_encoding" => "gzip")
    }

    specify {
      expect(result["Content-Encoding"]).to eq("gzip")
    }

  end # context

end # describe
