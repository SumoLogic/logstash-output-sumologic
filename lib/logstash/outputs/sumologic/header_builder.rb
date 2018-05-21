# encoding: utf-8
require "socket"
require "logstash/outputs/sumologic/common"

module LogStash; module Outputs; class SumoLogic;
  class HeaderBuilder

    include LogStash::Outputs::SumoLogic::Common

    CONTENT_TYPE = "Content-Type"
    CONTENT_TYPE_LOG = "text/plain"
    CONTENT_TYPE_GRAPHITE = "application/vnd.sumologic.graphite"
    CONTENT_TYPE_CARBON2 = "application/vnd.sumologic.carbon2"
    CONTENT_ENCODING = "Content-Encoding"

    CATEGORY_HEADER = "X-Sumo-Category"
    CATEGORY_HEADER_DEFAULT = "Logstash"
    HOST_HEADER = "X-Sumo-Host"
    NAME_HEADER = "X-Sumo-Name"
    NAME_HEADER_DEFAULT = "logstash-output-sumologic"

    CLIENT_HEADER = "X-Sumo-Client"
    CLIENT_HEADER_VALUE = "logstash-output-sumologic"

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
    
    def build()
      headers = build_common()
      headers[CATEGORY_HEADER] = @source_category unless @source_category.blank?
      append_content_header(headers)
      headers
    end # def build

    def build_stats()
      headers = build_common()
      headers[CATEGORY_HEADER] = "#{@source_category}.stats"
      headers[CONTENT_TYPE] = CONTENT_TYPE_CARBON2
      headers
    end # def build_stats

    private
    def build_common()
      headers = Hash.new()
      headers.merge!(@extra_headers)
      headers[CLIENT_HEADER] = CLIENT_HEADER_VALUE
      headers[HOST_HEADER] = @source_host unless @source_host.blank?
      headers[NAME_HEADER] = @source_name unless @source_name.blank?
      append_compress_header(headers)
      headers
    end # build_common

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