# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/outputs/sumologic"

describe LogStash::Outputs::SumoLogic::Compressor do

  context "compress (deflate)" do
    let(:compressor) {
      LogStash::Outputs::SumoLogic::Compressor.new("compress" => true, "compress_encoding" => "deflate")
    }
    specify {
      expect(compressor.compress("abcde").bytesize).to eq(13)
      expect(compressor.compress("aaaaa").bytesize).to eq(11)
    }
  end # context
  
  context "compress (gzip)" do
    let(:compressor) {
      LogStash::Outputs::SumoLogic::Compressor.new("compress" => true, "compress_encoding" => "gzip")
    }
    specify {
      expect(compressor.compress("abcde").bytesize).to eq(25)
      expect(compressor.compress("aaaaa").bytesize).to eq(23)
    }
  end # context

end # describe
