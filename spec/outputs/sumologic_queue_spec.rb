# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/outputs/sumologic"
require "logstash/event"

describe LogStash::Outputs::SumoLogic do

  let(:server) { subject.server }
  
  before :each do
    subject.register
    subject.receive(event)
  end