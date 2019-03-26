# encoding: utf-8

module LogStash; module Outputs; class SumoLogic;
  class Compressor

    require "stringio"
    require "zlib"
    require "logstash/outputs/sumologic/common"
    include LogStash::Outputs::SumoLogic::Common

    def initialize(config)
      @compress = config["compress"]
      @compress_encoding = (config["compress_encoding"] ||= DEFLATE).downcase
    end # def initialize

    def compress(content)
      if @compress
        if @compress_encoding == GZIP
          result = gzip(content)
          result.bytes.to_a.pack("c*")
        else
          Zlib::Deflate.deflate(content)
        end
      else
        content
      end
    end # def compress
    
    def gzip(content)
      stream = StringIO.new("w")
      stream.set_encoding("ASCII")
      gz = Zlib::GzipWriter.new(stream)
      gz.write(content)
      gz.close
      stream.string.bytes.to_a.pack("c*")
    end # def gzip
  
  end
end; end; end