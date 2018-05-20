# encoding: utf-8
require "date"

module LogStash; module Outputs; class SumoLogic;
  module Common

    # global constants
    DEFAULT_LOG_FORMAT = "%{@timestamp} %{host} %{message}"
    METRICS_NAME_PLACEHOLDER = "*"
    GRAPHITE = "graphite"
    CARBON2 = "carbon2"
    DEFLATE = "deflate"
    GZIP = "gzip"
    LOG_TO_CONSOLE = true

    def log_info(message, *opts)
      if LOG_TO_CONSOLE
        puts "[INFO:#{DateTime::now}]#{message} #{opts.to_s}"
      else
        @logger.info(message, opts)
      end
    end # def log_info

    def log_warn(message, *opts)
      if LOG_TO_CONSOLE
        puts "\e[33m[WARN:#{DateTime::now}]#{message} #{opts.to_s}\e[0m"
      else
        @logger.warn(message, opts)
      end
    end # def log_warn

    def log_err(message, *opts)
      if LOG_TO_CONSOLE
        puts "\e[31m[ERR :#{DateTime::now}]#{message} #{opts.to_s}\e[0m"
      else
        @logger.error(message, opts)
      end
    end # def log_err

    def log_dbg(message, *opts)
      if LOG_TO_CONSOLE
        puts "\e[36m[DBG :#{DateTime::now}]#{message} #{opts.to_s}\e[0m"
      else
        @logger.debug(message, opts)
      end
    end # def log_dbg

  end
end; end; end