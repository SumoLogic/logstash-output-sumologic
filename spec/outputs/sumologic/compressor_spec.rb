# encoding: utf-8
require "logstash/outputs/sumologic/compressor"

describe LogStash::Outputs::SumoLogic::Compressor do

  context "compress (deflate)" do
    let(:compressor) { LogStash::Outputs::SumoLogic::Compressor.new(true, "deflate") }
    specify {
      expect(compressor.compress_content("abcde").bytesize).to eq(13)
      expect(compressor.compress_content("aaaaa").bytesize).to eq(11)
    }
  end # context
  
  context "compress (gzip)" do
    let(:compressor) { LogStash::Outputs::SumoLogic::Compressor.new(true, "gzip") }
    specify {
      expect(compressor.compress_content("abcde").bytesize).to eq(25)
      expect(compressor.compress_content("aaaaa").bytesize).to eq(23)
    }
  end # context

end # describe
