# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/outputs/sumologic"
require "logstash/event"

describe LogStash::Outputs::SumoLogic do
  def url()
    ENV['sumo_http_url']
  end

end # describe
