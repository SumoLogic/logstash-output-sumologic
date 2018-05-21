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
    STATS_TAG = "STATS_TAG"

    # for debugging test
    LOG_TO_CONSOLE = false

    def set_logger(logger)
      @@logger = logger
    end

    def log_info(message, *opts)
      if LOG_TO_CONSOLE
        puts "[INFO:#{DateTime::now}]#{message} #{opts.to_s}"
      else
        @@logger && @@logger.info(message, opts)
      end
    end # def log_info

    def log_warn(message, *opts)
      if LOG_TO_CONSOLE
        puts "\e[33m[WARN:#{DateTime::now}]#{message} #{opts.to_s}\e[0m"
      else
        @@logger && @@logger.warn(message, opts)
      end
    end # def log_warn

    def log_err(message, *opts)
      if LOG_TO_CONSOLE
        puts "\e[31m[ERR :#{DateTime::now}]#{message} #{opts.to_s}\e[0m"
      else
        @@logger && @@logger.error(message, opts)
      end
    end # def log_err

    def log_dbg(message, *opts)
      if LOG_TO_CONSOLE
        puts "\e[36m[DBG :#{DateTime::now}]#{message} #{opts.to_s}\e[0m"
      else
        @@logger && @@logger.debug(message, opts)
      end
    end # def log_dbg

  end
end; end; end