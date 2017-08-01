
# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/outputs/sumologic"
require "logstash/event"

require_relative '../spec_helper'

describe LogStash::Outputs::SumoLogic do

  let(:server) { subject.server }
  
  before :each do
    subject.register
    subject.receive(event)
  end

  context "with log sent in default format" do

    subject { LogStash::Outputs::SumoLogic.new("url" => "http://localhost/1234") }
    let(:event) { LogStash::Event.new("host" => "myHost", "message" => "Hello world") }

    it "generate one element" do
      expect(server.size).to eq(1)
    end

    it "include all content" do
      received = server.pop
      expect(received).to match(/myHost/)
      expect(received).to match(/Hello\sworld/)
    end

  end

  context "with log sent in json" do

    subject { LogStash::Outputs::SumoLogic.new("url" => "http://localhost/1234", "format" => "%{@json}") }
    let(:event) { LogStash::Event.new("host" => "myHost", "message" => "Hello world") }

    it "generate one element" do
      expect(server.size).to eq(1)
    end

    it "include all content" do
      received = server.pop.to_s
      expect(received).to include("\"host\":\"myHost\"")
      expect(received).to include("\"message\":\"Hello world\"")
    end

  end

end
