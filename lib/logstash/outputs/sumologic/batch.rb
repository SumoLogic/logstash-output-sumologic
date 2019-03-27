# encoding: utf-8

module LogStash; module Outputs; class SumoLogic;
  class Batch
    
    attr_accessor :headers, :payload
  
    def initialize(headers, payload)
        @headers, @payload = headers, payload
    end
  
  end
end; end; end;
