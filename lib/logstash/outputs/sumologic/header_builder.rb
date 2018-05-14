# encoding: utf-8

module LogStash; module Outputs; class SumoLogic;
  module HeaderBuilder

    include LogStash::Outputs::SumoLogic::Common
    
    def build_header()

      headers = @extra_headers.is_a?(Hash) ? @extra_headers : {}
      headers[CLIENT_HEADER] = CLIENT_HEADER_VALUE

      headers[CATEGORY_HEADER] = @source_category ? @source_category : CATEGORY_HEADER_DEFAULT
      headers[HOST_HEADER] = @source_host ? @source_host : Socket.gethostname
      headers[NAME_HEADER] = @source_name ? @source_name : NAME_HEADER_DEFAULT

      append_content_header(headers)
      append_compress_header(headers)

      log_dbg(
        "HTTP headers built out",
        :headers => headers
      )

      headers
    end # def build

    private
    def append_content_header(headers)
      contentType = CONTENT_TYPE_LOG
      if @metrics || @fields_as_metrics
        if @metrics_format == CARBON2
          contentType = CONTENT_TYPE_CARBON2
        elsif @metrics_format == GRAPHITE
          contentType = CONTENT_TYPE_GRAPHITE
        else
          log_err(
            "Unrecogonized metrics format",
            :format => @metrics_format
          )
        end
      end
      log_dbg(
        "Content type is set",
        :contentType => contentType
      )
      headers[CONTENT_TYPE] = contentType
    end # def append_content_header

    private
    def append_compress_header(headers)
      if @compress
        if @compress_encoding == GZIP
          headers[CONTENT_ENCODING] = GZIP
        elsif
          headers[CONTENT_ENCODING] = DEFLATE
        else
          log_err(
            "Unrecogonized compress encoding",
            :encoding => @compress_encoding
          )
        end
      end
    end # append_compress_header

  end
end; end; end