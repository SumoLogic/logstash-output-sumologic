# encoding: utf-8
require "logstash/json"
require "logstash/event"

require "logstash/outputs/sumologic/common"

module LogStash; module Outputs; class SumoLogic;
  class PayloadBuilder
    
    include LogStash::Outputs::SumoLogic::Common

    TIMESTAMP_FIELD = "@timestamp"
    METRICS_NAME_TAG = "metric"
    JSON_PLACEHOLDER = "%{@json}"
    ALWAYS_EXCLUDED = [ "@timestamp", "@version" ]
    
    def initialize(config)
      
      @format = config["format"] ||= DEFAULT_LOG_FORMAT
      @json_mapping = config["json_mapping"]

      @metrics = config["metrics"]
      @metrics_name = config["metrics_name"]
      @fields_as_metrics = config["fields_as_metrics"]
      @metrics_format = (config["metrics_format"] ||= CARBON2).downcase
      @intrinsic_tags = config["intrinsic_tags"] ||= {}
      @meta_tags = config["meta_tags"] ||= {}
      @fields_include = config["fields_include"] ||= []
      @fields_exclude = config["fields_exclude"] ||= []

    end # def initialize

    def build(event)
      payload = if @metrics || @fields_as_metrics
        build_metrics_payload(event)
      else
        build_log_payload(event)
      end
      payload
    end # def build
  
    private

    def build_log_payload(event)
      apply_template(@format, event)
    end # def event2log
  
    def build_metrics_payload(event)
      timestamp = event.get(TIMESTAMP_FIELD).to_i
      source = if @fields_as_metrics
        event_as_metrics(event)
      else
        expand_hash(@metrics, event)
      end
      source.flat_map { |key, value|
        get_single_line(event, key, value, timestamp)
      }.reject(&:nil?).join("\n")
    end # def event2metrics
  
    def event_as_metrics(event)
      hash = event2hash(event)
      acc = {}
      hash.keys.each do |field|
        value = hash[field]
        dotify(acc, field, value, nil)
      end
      acc
    end # def event_as_metrics
  
    def get_single_line(event, key, value, timestamp)
      full = get_metrics_name(event, key)
      if !ALWAYS_EXCLUDED.include?(full) &&  \
        (@fields_include.empty? || @fields_include.any? { |regexp| full.match(regexp) }) && \
        !(@fields_exclude.any? {|regexp| full.match(regexp)}) && \
        is_number?(value)
        if @metrics_format == GRAPHITE
          "#{full} #{value} #{timestamp}" 
        else
          @intrinsic_tags[METRICS_NAME_TAG] = full
          "#{hash2line(@intrinsic_tags, event)} #{hash2line(@meta_tags, event)}#{value} #{timestamp}"
        end
      end
    end # def get_single_line
  
    def dotify(acc, key, value, prefix)
      pk = prefix ? "#{prefix}.#{key}" : key.to_s
      if value.is_a?(Hash)
        value.each do |k, v|
          dotify(acc, k, v, pk)
        end
      elsif value.is_a?(Array)
        value.each_with_index.map { |v, i|
          dotify(acc, i.to_s, v, pk)
        }
      else
        acc[pk] = value
      end
    end # def dotify
  
    def event2hash(event)
      if @json_mapping
        @json_mapping.reduce({}) do |acc, kv|
          k, v = kv
          acc[k] = event.sprintf(v)
          acc
        end
      else
        event.to_hash
      end
    end # def map_event
  
    def is_number?(me)
      me.to_f.to_s == me.to_s || me.to_i.to_s == me.to_s
    end # def is_number?
  
    def expand_hash(hash, event)
      hash.reduce({}) do |acc, kv|
        k, v = kv
        exp_k = apply_template(k, event)
        exp_v = apply_template(v, event)
        acc[exp_k] = exp_v
        acc
      end
    end # def expand_hash
    
    def apply_template(template, event)
      if template.include? JSON_PLACEHOLDER
        hash = event2hash(event)
        dump = LogStash::Json.dump(hash)
        template = template.gsub(JSON_PLACEHOLDER) { dump }
      end
      event.sprintf(template)
    end # def expand
    
    def get_metrics_name(event, name)
      name = @metrics_name.gsub(METRICS_NAME_PLACEHOLDER) { name } if @metrics_name
      event.sprintf(name)
    end # def get_metrics_name
  
    def hash2line(hash, event)
      if (hash.is_a?(Hash) && !hash.empty?)
        expand_hash(hash, event).flat_map { |k, v|
          "#{k}=#{v} "
        }.join()
      else
        ""
      end
    end # def hash2line
    
  end
end; end; end