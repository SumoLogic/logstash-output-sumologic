# encoding: utf-8

module LogStash; module Outputs; class SumoLogic;
  class HeaderBuilder

    require "socket"
    require "logstash/outputs/sumologic/common"
    include LogStash::Outputs::SumoLogic::Common

    def initialize(config)
      
      @extra_headers = config["extra_headers"] ||= {}
      @source_category = config["source_category"] ||= CATEGORY_HEADER_DEFAULT
      @source_host = config["source_host"] ||= Socket.gethostname
      @source_name = config["source_name"] ||= NAME_HEADER_DEFAULT
      @metrics = config["metrics"]
      @fields_as_metrics = config["fields_as_metrics"]
      @metrics_format = (config["metrics_format"] ||= CARBON2).downcase
      @compress = config["compress"]
      @compress_encoding = config["compress_encoding"]

    end # def initialize
    
    def build(event)
      headers = Hash.new
      headers.merge!(@extra_headers)
      headers[CLIENT_HEADER] = CLIENT_HEADER_VALUE
      headers[CATEGORY_HEADER] = event.sprintf(@source_category) unless blank?(@source_category)
      headers[HOST_HEADER] = event.sprintf(@source_host) unless blank?(@source_host)
      headers[NAME_HEADER] = event.sprintf(@source_name) unless blank?(@source_name)
      append_content_header(headers)
      append_compress_header(headers)
      headers
    end # def build

    private
    def append_content_header(headers)
      contentType = CONTENT_TYPE_LOG
      if @metrics || @fields_as_metrics
        contentType = (@metrics_format == GRAPHITE) ? CONTENT_TYPE_GRAPHITE : CONTENT_TYPE_CARBON2
      end
      headers[CONTENT_TYPE] = contentType
    end # def append_content_header

    def append_compress_header(headers)
      if @compress
        headers[CONTENT_ENCODING] = (@compress_encoding == GZIP) ? GZIP : DEFLATE
      end
    end # append_compress_header

  end
end; end; end
