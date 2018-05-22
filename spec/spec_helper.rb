# encoding: utf-8

require "logstash/devutils/rspec/spec_helper"
require "logstash/outputs/sumologic"
  
class Server
  
  def initialize
    @queue = Queue.new
    @header = {}
  end

  def size
    @queue.length
  end

  def all
    @queue.size.times.map { @queue.pop }
  end

  def all_sorted
    all.sort { |x, y| y <=> x }
  end

  def pop
    if !@queue.empty?
      @queue.pop
    else
      puts "EMPTY"
    end
  end

  def header
    @header
  end

  def empty?
    @queue.empty?
  end

  def push(data, header)
    @header = header
    data.split("\n").each do |line|
      @queue << line
    end
  end

end

class LogStash::Outputs::SumoLogic
  attr_reader :server
  
  def connect
    @server = Server.new
  end
  
  def send_request(content, key=nil)
    @server.push(content, get_headers(key))
  end

end
