# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/outputs/sumologic"
require_relative "../../test_server.rb"

describe LogStash::Outputs::SumoLogic::Sender do

  before :all do
    @@server = TestServer.new()
    @@server.start()
  end

  before :each do
    @@server.response = TestServer::RESPONSE_200
    @@server.all_requests()
  end

  after :all do
    @@server.stop()
  end

  context "connect()" do
    let(:plugin) { LogStash::Outputs::SumoLogic.new("url" => "http://localhost:#{TestServer::PORT}") }

    it "return true if sever response 200" do
      expect(plugin.connect(false)).to be true
      result = @@server.all_requests()
      expect(result.size).to eq(1)
    end

    it "return false if sever response 429" do
      @@server.response = TestServer::RESPONSE_429
      expect(plugin.connect(false)).to be false
      result = @@server.all_requests()
      expect(result.size).to eq(1)
    end

    it "return false if sever cannot reach" do
      plugin = LogStash::Outputs::SumoLogic.new("url" => "http://localhost:4321")
      expect(plugin.connect(false)).to be false
      result = @@server.all_requests()
      expect(result.size).to eq(0)
    end

  end # context

end # describe

