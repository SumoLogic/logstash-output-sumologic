# encoding: utf-8
require "stringio"
require "zlib"

require_relative './common'

module LogStash; module Outputs; class SumoLogic;
  class Compressor

    include LogStash::Outputs::SumoLogic::Common

    def initialize(compress, compress_encoding)
      @compress = compress
      @compress_encoding = compress_encoding
    end # def initialize

    def compress_content(content)
      if @compress
        if @compress_encoding == GZIP
          result = gzip(content)
          result.bytes.to_a.pack('c*')
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
      stream.string.bytes.to_a.pack('c*')
    end # def gzip
  
  end
end; end; end