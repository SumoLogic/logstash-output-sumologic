module LogStash; module Outputs; class SumoLogic;
  module Common

    # global constants
    CONTENT_TYPE = "Content-Type"
    CONTENT_TYPE_LOG = "text/plain"
    CONTENT_TYPE_GRAPHITE = "application/vnd.sumologic.graphite"
    CONTENT_TYPE_CARBON2 = "application/vnd.sumologic.carbon2"
    CATEGORY_HEADER = "X-Sumo-Category"
    CATEGORY_HEADER_DEFAULT = "Logstash"
    HOST_HEADER = "X-Sumo-Host"
    NAME_HEADER = "X-Sumo-Name"
    NAME_HEADER_DEFAULT = "logstash-output-sumologic"
    CLIENT_HEADER = "X-Sumo-Client"
    CLIENT_HEADER_VALUE = "logstash-output-sumologic"
    TIMESTAMP_FIELD = "@timestamp"
    METRICS_NAME_PLACEHOLDER = "*"
    GRAPHITE = "graphite"
    CARBON2 = "carbon2"
    CONTENT_ENCODING = "Content-Encoding"
    DEFLATE = "deflate"
    GZIP = "gzip"
    ALWAYS_EXCLUDED = [ "@timestamp", "@version" ]
    LOG_TO_CONSOLE = true

    def log_info(message, opts)
      if LOG_TO_CONSOLE
        puts "[INFO:#{DateTime::now}]#{message} #{opts.to_s}"
      else
        @logger.info(message, opts)
      end
    end # def log_info

    def log_warn(message, opts)
      if LOG_TO_CONSOLE
        puts "\e[33m[WARN:#{DateTime::now}]#{message} #{opts.to_s}\e[0m"
      else
        @logger.warn(message, opts)
      end
    end # def log_warn

    def log_err(message, opts)
      if LOG_TO_CONSOLE
        puts "\e[31m[ERR :#{DateTime::now}]#{message} #{opts.to_s}\e[0m"
      else
        @logger.error(message, opts)
      end
    end # def log_err

    def log_dbg(message, opts)
      if LOG_TO_CONSOLE
        puts "\e[36m[DBG :#{DateTime::now}]#{message} #{opts.to_s}\e[0m"
      else
        @logger.debug(message, opts)
      end
    end # def log_dbg

  end
end; end; end