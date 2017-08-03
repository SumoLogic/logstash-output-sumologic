# encoding: utf-8

require "logstash/devutils/rspec/spec_helper"
require "logstash/outputs/sumologic"
  
class Server
  
  def initialize
    @queue = Array.new
  end

  def size
    @queue.length
  end

  def pop
    @queue.pop
  end

  def empty?
    @queue.empty?
  end

  def puts(data)
    data.split("\n").each do |line|
      @queue << "#{line}\n"
    end
  end
end

class LogStash::Outputs::SumoLogic
  attr_reader :server
  
  def connect
    @server = Server.new
  end
  
  def send_request(content)
    @server.puts(content)
  end

end