# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/outputs/sumologic"
require "rspec/eventually"

require_relative "../../test_server.rb"

describe LogStash::Outputs::SumoLogic::Sender do

  before :all do
    @@server = TestServer.new()
    @@server.start()
  end

  before :each do
    @@server.response = TestServer::RESPONSE_200
    @@server.drain()
  end

  after :all do
    @@server.stop()
  end

  context "connect()" do
    let(:stats) { LogStash::Outputs::SumoLogic::Statistics.new() }
    let(:queue) { LogStash::Outputs::SumoLogic::MessageQueue.new(stats, "queue_max" => 10) }
    let(:sender) { LogStash::Outputs::SumoLogic::Sender.new(false, queue, stats, "url" => "http://localhost:#{TestServer::PORT}") }

    it "should return true if sever response 200" do
      expect(sender.connect()).to be true
      result = @@server.drain()
      expect(result.size).to eq(1)
    end

    it "should return false if sever response 429" do
      @@server.response = TestServer::RESPONSE_429
      expect(sender.connect()).to be false
      result = @@server.drain()
      expect(result.size).to eq(1)
    end

    it "should return false if sever cannot reach" do
      sender = LogStash::Outputs::SumoLogic::Sender.new(false, queue, stats, "url" => "http://localhost:#{TestServer::PORT + 1}")
      expect(sender.connect()).to be false
      result = @@server.drain()
      expect(result.size).to eq(0)
    end

  end # context

  context "single sender" do
    let(:plugin) { LogStash::Outputs::SumoLogic.new("url" => "http://localhost:#{TestServer::PORT}", "sender_max" => 1, "sleep_before_requeue" => 1, "request_timeout" => 3) }
    let(:event) { LogStash::Event.new("host" => "myHost", "message" => "Hello world") }

    it "should send message correctly" do
      plugin.register
      plugin.receive(event)
      expect { plugin.stats.total_request }.to eventually(eq(1)).pause_for(1)
      expect { plugin.stats.total_response[200] }.to eventually(eq(1)).pause_for(1)
      result = @@server.drain()
      expect(result.size).to eq(2)
      plugin.receive(event)
      expect { plugin.stats.total_request }.to eventually(eq(2)).pause_for(1)
      expect { plugin.stats.total_response[200] }.to eventually(eq(2)).pause_for(1)
      result = @@server.drain()
      expect(result.size).to eq(1)
    end

    it "should re-enque the message if got 429" do
      plugin.register
      plugin.receive(event)
      expect { plugin.stats.total_request }.to eventually(eq(1)).pause_for(1)
      expect { plugin.stats.total_response[200] }.to eventually(eq(1)).pause_for(1)
      result = @@server.drain()
      expect(result.size).to eq(2)
      @@server.response = TestServer::RESPONSE_429
      plugin.receive(event)
      expect { plugin.stats.total_request }.to eventually(be > 1).within(10).pause_for(1)
      expect { plugin.stats.total_response[429] }.to eventually(be > 1).within(10).pause_for(1)
      result = @@server.drain()
      expect(result.size).to be > 0
      @@server.response = TestServer::RESPONSE_200
      expect { plugin.stats.total_response[200] }.to eventually(be > 1).within(10).pause_for(1)
      result = @@server.drain()
      expect(result.size).to be > 0
    end

    it "should re-enque the message if network failed" do
      plugin.register
      plugin.receive(event)
      expect { plugin.stats.total_request }.to eventually(eq(1)).pause_for(1)
      expect { plugin.stats.total_response[200] }.to eventually(eq(1)).pause_for(1)
      result = @@server.drain()
      expect(result.size).to eq(2)
      @@server.stop()
      plugin.receive(event)
      expect { plugin.stats.total_request }.to eventually(be > 1).within(10).pause_for(1)
      expect { plugin.stats.total_response["failure"] }.to eventually(be > 1).within(25).pause_for(1)
      result = @@server.drain()
      @@server.start()
      @@server.response = TestServer::RESPONSE_200
      expect { plugin.stats.total_response[200] }.to eventually(be > 1).within(10).pause_for(1)
      result = @@server.drain()
      expect(result.size).to be > 0
    end

  end # context

  context "multiple senders" do
    let(:plugin) { LogStash::Outputs::SumoLogic.new("url" => "http://localhost:#{TestServer::PORT}", "sender_max" => 10, "sleep_before_requeue" => 1, "request_timeout" => 3) }
    let(:event) { LogStash::Event.new("host" => "myHost", "message" => "Hello world") }

    it "should send message correctly" do
      plugin.register
      plugin.receive(event)
      expect { plugin.stats.total_request }.to eventually(eq(1)).pause_for(1)
      expect { plugin.stats.total_response[200] }.to eventually(eq(1)).pause_for(1)
      result = @@server.drain()
      expect(result.size).to eq(2)
      plugin.receive(event)
      expect { plugin.stats.total_request }.to eventually(eq(2)).pause_for(1)
      expect { plugin.stats.total_response[200] }.to eventually(eq(2)).pause_for(1)
      result = @@server.drain()
      expect(result.size).to eq(1)
    end

    it "should re-enque the message if got 429" do
      plugin.register
      plugin.receive(event)
      expect { plugin.stats.total_request }.to eventually(eq(1)).pause_for(1)
      expect { plugin.stats.total_response[200] }.to eventually(eq(1)).pause_for(1)
      result = @@server.drain()
      expect(result.size).to eq(2)
      @@server.response = TestServer::RESPONSE_429
      plugin.receive(event)
      expect { plugin.stats.total_request }.to eventually(be > 1).within(10).pause_for(1)
      expect { plugin.stats.total_response[429] }.to eventually(be > 1).within(10).pause_for(1)
      result = @@server.drain()
      expect(result.size).to be > 0
      @@server.response = TestServer::RESPONSE_200
      expect { plugin.stats.total_response[200] }.to eventually(be > 1).within(10).pause_for(1)
      result = @@server.drain()
      expect(result.size).to be > 0
    end
    
    it "should re-enque the message if network failed" do
      plugin.register
      plugin.receive(event)
      expect { plugin.stats.total_request }.to eventually(eq(1)).pause_for(1)
      expect { plugin.stats.total_response[200] }.to eventually(eq(1)).pause_for(1)
      result = @@server.drain()
      expect(result.size).to eq(2)
      @@server.stop()
      plugin.receive(event)
      expect { plugin.stats.total_request }.to eventually(be > 1).within(10).pause_for(1)
      expect { plugin.stats.total_response["failure"] }.to eventually(be > 1).within(25).pause_for(1)
      result = @@server.drain()
      @@server.start()
      @@server.response = TestServer::RESPONSE_200
      expect { plugin.stats.total_response[200] }.to eventually(be > 1).within(10).pause_for(1)
      result = @@server.drain()
      expect(result.size).to be > 0
    end

    it "should reuse tokens" do
      plugin.register
      30.times { plugin.receive(event) }
      expect { plugin.stats.total_response[200] }.to eventually(eq 30).within(100).pause_for(1)
    end

  end # context

  context "close()" do

    let(:plugin) { LogStash::Outputs::SumoLogic.new("url" => "http://localhost:#{TestServer::PORT}", "sender_max" => 10) }
    let(:event) { LogStash::Event.new("host" => "myHost", "message" => "Hello world") }

    it "should drain out messages" do
      plugin.register
      30.times { plugin.receive(event) }
      plugin.close
      expect(plugin.stats.total_response[200]).to eq 31
    end

  end # context

end # describe

