# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/outputs/sumologic"

describe LogStash::Outputs::SumoLogic::HeaderBuilder do

  result = {}
  event = LogStash::Event.new("foo" => "bar", "message" => "Hello world")

  before :each do
    result = builder.build(event)
  end

  context "should build headers by default" do

    let(:builder) { LogStash::Outputs::SumoLogic::HeaderBuilder.new("url" => "http://localhost/1234") }

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
    
    let(:builder) {
      LogStash::Outputs::SumoLogic::HeaderBuilder.new(
        "url" => "http://localhost/1234",
        "source_category" => "my source category")
    }

    specify {
      expect(result.count).to eq(5)
      expect(result["X-Sumo-Category"]).to eq("my source category")
    }

  end # context

  context "should override source_category with template" do
    
    let(:builder) {
      LogStash::Outputs::SumoLogic::HeaderBuilder.new(
        "url" => "http://localhost/1234",
        "source_category" => "my source category %{foo}")
    }

    specify {
      expect(result.count).to eq(5)
      expect(result["X-Sumo-Category"]).to eq("my source category bar")
    }

  end # context

  context "should override source_name" do
    
    let(:builder) {
      LogStash::Outputs::SumoLogic::HeaderBuilder.new(
        "url" => "http://localhost/1234",
        "source_name" => "my source name")
    }

    specify {
      expect(result.count).to eq(5)
      expect(result["X-Sumo-Name"]).to eq("my source name")
    }

  end # context

  context "should override source_name with template" do
    
    let(:builder) {
      LogStash::Outputs::SumoLogic::HeaderBuilder.new(
        "url" => "http://localhost/1234",
        "source_name" => "my source name %{foo}")
    }

    specify {
      expect(result.count).to eq(5)
      expect(result["X-Sumo-Name"]).to eq("my source name bar")
    }

  end # context

  context "should override source_host" do
    
    let(:builder) {
      LogStash::Outputs::SumoLogic::HeaderBuilder.new(
        "url" => "http://localhost/1234",
        "source_host" => "my source host")
    }

    specify {
      expect(result.count).to eq(5)
      expect(result["X-Sumo-Host"]).to eq("my source host")
    }

  end # context

  context "should override source_host with template" do
    
    let(:builder) {
      LogStash::Outputs::SumoLogic::HeaderBuilder.new(
        "url" => "http://localhost/1234",
        "source_host" => "my source host %{foo}")
    }

    specify {
      expect(result.count).to eq(5)
      expect(result["X-Sumo-Host"]).to eq("my source host bar")
    }

  end # context

  context "should hornor extra_headers" do
    
    let(:builder) {
      LogStash::Outputs::SumoLogic::HeaderBuilder.new(
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
    
    let(:builder) {
      LogStash::Outputs::SumoLogic::HeaderBuilder.new(
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

    let(:builder) {
      LogStash::Outputs::SumoLogic::HeaderBuilder.new("url" => "http://localhost/1234")
    }

    specify {
      expect(result["Content-Type"]).to eq("text/plain")
    }

  end # context

  context "should set content type correctly for metrics payload (CarbonV2, default)" do

    let(:builder) {
      LogStash::Outputs::SumoLogic::HeaderBuilder.new(
        "url" => "http://localhost/1234",
        "fields_as_metrics" => true)
    }

    specify {
      expect(result["Content-Type"]).to eq("application/vnd.sumologic.carbon2")
    }

  end # context

  context "should set content type correctly for metrics payload (Graphite)" do

    let(:builder) {
      LogStash::Outputs::SumoLogic::HeaderBuilder.new(
        "url" => "http://localhost/1234",
        "metrics_format" => "graphite",
        "fields_as_metrics" => true)
    }

    specify {
      expect(result["Content-Type"]).to eq("application/vnd.sumologic.graphite")
    }

  end # context

  context "should set content encoding correctly for uncompressed payload" do

    let(:builder) {
      LogStash::Outputs::SumoLogic::HeaderBuilder.new("url" => "http://localhost/1234")
    }

    specify {
      expect(result["Content-Encoding"]).to be_nil
    }

  end # context

  context "should set content encoding correctly for compressed payload (deflate, default)" do

    let(:builder) {
      LogStash::Outputs::SumoLogic::HeaderBuilder.new("url" => "http://localhost/1234", "compress" => true)
    }

    specify {
      expect(result["Content-Encoding"]).to eq("deflate")
    }

  end # context

  context "should set content encoding correctly for compressed payload (gzip)" do

    let(:builder) {
      LogStash::Outputs::SumoLogic::HeaderBuilder.new("url" => "http://localhost/1234", "compress" => true, "compress_encoding" => "gzip")
    }

    specify {
      expect(result["Content-Encoding"]).to eq("gzip")
    }

  end # context

  context "should build headers for stats" do
    let(:builder) {
      LogStash::Outputs::SumoLogic::HeaderBuilder.new("url" => "http://localhost/1234")
    }

    specify {
      stats_result = builder.build_stats()
      expected = {
        "X-Sumo-Client" => "logstash-output-sumologic",
        "X-Sumo-Name" => "logstash-output-sumologic",
        "X-Sumo-Host" => Socket.gethostname,
        "X-Sumo-Category" => "Logstash.stats",
        "Content-Type" => "application/vnd.sumologic.carbon2"
      }
      expect(stats_result).to eq(expected)
    }
  end

  context "should build headers for stats with overridden source category" do
    let(:builder) {
      LogStash::Outputs::SumoLogic::HeaderBuilder.new("url" => "http://localhost/1234", "stats_category" => "custom")
    }

    specify {
      stats_result = builder.build_stats()
      expect(stats_result["X-Sumo-Category"]).to eq("custom")
    }
  end

  context "should build headers for stats with compression" do
    let(:builder) {
      LogStash::Outputs::SumoLogic::HeaderBuilder.new("url" => "http://localhost/1234", "compress" => true, "compress_encoding" => "gzip")
    }

    specify {
      stats_result = builder.build_stats()
      expect(stats_result["Content-Encoding"]).to eq("gzip")
    }
  end

  context "should build headers for stats with extra_headers" do
    let(:builder) {
      LogStash::Outputs::SumoLogic::HeaderBuilder.new(
        "url" => "http://localhost/1234",
        "extra_headers" => {
          "foo" => "bar"
        })
    }

    specify {
      stats_result = builder.build_stats()
      expect(stats_result.count).to eq(6)
      expect(stats_result["foo"]).to eq("bar")
    }
  end

  context "should build headers for stats with extra_headers but never overwrite pre-defined headers" do
    
    let(:builder) {
      LogStash::Outputs::SumoLogic::HeaderBuilder.new(
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
      stats_result = builder.build_stats()
      expected = {
        "foo" => "bar",
        "X-Sumo-Client" => "logstash-output-sumologic",
        "X-Sumo-Name" => "logstash-output-sumologic",
        "X-Sumo-Host" => Socket.gethostname,
        "X-Sumo-Category" => "Logstash.stats",
        "Content-Type" => "application/vnd.sumologic.carbon2"
      }
      expect(stats_result).to eq(expected)
    }

  end # context

end # describe
