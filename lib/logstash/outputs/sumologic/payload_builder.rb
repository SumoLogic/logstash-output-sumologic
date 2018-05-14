# encoding: utf-8
require "logstash/json"

module LogStash; module Outputs; class SumoLogic;
  module PayloadBuilder
    
    include LogStash::Outputs::SumoLogic::Common
    
    def build_payload(event)
      payload = if @metrics || @fields_as_metrics
        build_metrics_payload(event)
      else
        build_log_payload(event)
      end
      payload
    end
  
    private
    def build_log_payload(event)
      log_dbg("build log payload from event", :event => event.to_hash)
      apply_template(@format, event)
    end # def event2log
  
    private
    def build_metrics_payload(event)
      log_dbg("build metrics payload from event", :event => event.to_hash)
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
  
    private
    def event_as_metrics(event)
      hash = event2hash(event)
      acc = {}
      hash.keys.each do |field|
        value = hash[field]
        dotify(acc, field, value, nil)
      end
      acc
    end # def event_as_metrics
  
    private
    def get_single_line(event, key, value, timestamp)
      full = get_metrics_name(event, key)
      if !ALWAYS_EXCLUDED.include?(full) &&  \
        (fields_include.empty? || fields_include.any? { |regexp| full.match(regexp) }) && \
        !(fields_exclude.any? {|regexp| full.match(regexp)}) && \
        is_number?(value)
        if @metrics_format == CARBON2
          @intrinsic_tags["metric"] = full
          "#{hash2line(@intrinsic_tags, event)} #{hash2line(@meta_tags, event)}#{value} #{timestamp}"
        else
          "#{full} #{value} #{timestamp}" 
        end
      end
    end # def get_single_line
  
    private
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
  
    private 
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
  
    private
    def is_number?(me)
      me.to_f.to_s == me.to_s || me.to_i.to_s == me.to_s
    end # def is_number?
  
    private
    def expand_hash(hash, event)
      hash.reduce({}) do |acc, kv|
        k, v = kv
        exp_k = apply_template(k, event)
        exp_v = apply_template(v, event)
        acc[exp_k] = exp_v
        acc
      end
    end # def expand_hash
    
    private
    def apply_template(template, event)
      if template.include? "%{@json}"
        hash = event2hash(event)
        dump = LogStash::Json.dump(hash)
        template = template.gsub("%{@json}") { dump }
      end
      event.sprintf(template)
    end # def expand
    
    private
    def get_metrics_name(event, name)
      name = @metrics_name.gsub(METRICS_NAME_PLACEHOLDER) { name } if @metrics_name
      event.sprintf(name)
    end # def get_metrics_name
  
    private
    def hash2line(hash, event)
      if (hash.is_a?(Hash) && !hash.empty?)
        expand_hash(hash, event).flat_map { |k, v|
          "#{k}=#{v} "
        }.join()
      else
        ""
      end
    end # hash2line
    
  end
end; end; end