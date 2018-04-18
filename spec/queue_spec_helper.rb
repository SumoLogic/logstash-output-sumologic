# encoding: utf-8

require "logstash/devutils/rspec/spec_helper"
require "logstash/outputs/sumologic"

class Request
  attr_reader :header
  attr_reader :payload
end

class Server

  def initialize
    @requests = Queue.new
  end

  def count
    @requests.length
  end

  def pop_requests
    @requests.size.times.map { @requests.pop }
  end

  def pop_payloads
    pop_requests.map { |r| => r.payload }
  end

  def pop_headers
    pop_requests.map { |r| => r.header }
  end

  def empty?
    @requests.empty?
  end

  def push(header, payload)
    request = Request.new(:header => header, :payload => payload)
    @requests << request
  end

end

class LogStash::Outputs::SumoLogic
  attr_reader :server
  
  def connect
    @server = Server.new
  end
  
  def send_request(content)
    @server.push(get_headers(), content)
  end

end
