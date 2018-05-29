# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "rspec/eventually"
require "logstash/outputs/sumologic"

describe LogStash::Outputs::SumoLogic, :unless => (ENV["sumo_url"].to_s.empty?) do

  before :each do
    plugin.register()
  end

  after :each do
    plugin.close()
  end

  context "no pile" do
    context "single sender" do
      context "send log in json" do
        let(:plugin) { 
          LogStash::Outputs::SumoLogic.new(
            "url" => ENV["sumo_url"], 
            "sender_max" => 1,
            "format" => "%{@json}")
        }
        specify {
          event = LogStash::Event.new("host" => "myHost", "message" => "Hello world")
          plugin.receive(event)
          expect { plugin.stats.total_output_requests.value }.to eventually(be > 0).within(10).pause_for(1)
          expect { plugin.stats.total_response("200") }.to eventually(be > 0).within(10).pause_for(1)
        }
      end
      context "send fields as metrics" do
        let(:plugin) { 
          LogStash::Outputs::SumoLogic.new(
            "url" => ENV["sumo_url"],
            "sender_max" => 1,
            "fields_as_metrics" => true,
            "intrinsic_tags" => {
              "host"=>"%{host}"
            },
            "meta_tags" => {
              "foo" => "%{foo}"
            })
        }

        specify {
          event = LogStash::Event.new(
            "host" => "myHost",
            "foo" => "fancy",
            "cpu" => [0.24, 0.11, 0.75, 0.28],
            "storageRW" => 51,
            "bar" => "blahblah",
            "blkio" => {
              "write_ps" => 5,
              "read_ps" => 2,
              "total_ps" => 0
            })
          
          plugin.receive(event)
          expect { plugin.stats.total_output_requests.value }.to eventually(be > 0).within(10).pause_for(1)
          expect { plugin.stats.total_response("200") }.to eventually(be > 0).within(10).pause_for(1)
        }
      end
    end
    context "multiple senders" do
      context "send log in json" do
        let(:plugin) {
          LogStash::Outputs::SumoLogic.new(
            "url" => ENV["sumo_url"], 
            "sender_max" => 5,
            "format" => "%{@json}")
        }
        
        specify {
          5.times { |t| 
            event = LogStash::Event.new("host" => "myHost", "message" => "Hello world - #{t}")
            plugin.receive(event)
          } 
          expect { plugin.stats.total_output_requests.value }.to eventually(be > 0).within(10).pause_for(1)
          expect { plugin.stats.total_response("200") }.to eventually(be > 0).within(10).pause_for(1)
        }
      end

      context "send multiple log in json" do
        let(:plugin) {
          LogStash::Outputs::SumoLogic.new(
            "url" => ENV["sumo_url"], 
            "sender_max" => 5,
            "format" => "%{@json}"
          )
        }
        
        specify {
          5.times { |t| 
            events = 10.times.map { |r|
              LogStash::Event.new("host" => "myHost", "message" => "Hello world - #{t} - #{r}")
            }
            plugin.multi_receive(events)
          } 
          expect { plugin.stats.total_output_requests.value }.to eventually(be > 0).within(10).pause_for(1)
          expect { plugin.stats.total_response("200") }.to eventually(be > 0).within(10).pause_for(1)
        }
      end
    end
  end
  context "has pile" do
    context "single sender" do
      context "send log in json" do
        let(:plugin) {
          LogStash::Outputs::SumoLogic.new(
            "url" => ENV["sumo_url"], 
            "sender_max" => 1,
            "interval" => 3,
            "format" => "%{@json}")
        }
        
        specify {
          5.times { |t| 
            event = LogStash::Event.new("host" => "myHost", "message" => "Hello world - #{t}")
            plugin.receive(event)
          } 
          expect { plugin.stats.total_output_requests.value }.to eventually(be > 0).within(10).pause_for(1)
          expect { plugin.stats.total_response("200") }.to eventually(be > 0).within(10).pause_for(1)
        }
      end

      context "send multiple log in json" do
        let(:plugin) {
          LogStash::Outputs::SumoLogic.new(
            "url" => ENV["sumo_url"], 
            "sender_max" => 1,
            "interval" => 3,
            "format" => "%{@json}"
          )
        }
        
        specify {
          5.times { |t| 
            events = 10.times.map { |r|
              LogStash::Event.new("host" => "myHost", "message" => "Hello world - #{t} - #{r}")
            }
            plugin.multi_receive(events)
          } 
          expect { plugin.stats.total_output_requests.value }.to eventually(be > 0).within(10).pause_for(1)
          expect { plugin.stats.total_response("200") }.to eventually(be > 0).within(10).pause_for(1)
        }
      end
    end
    context "multi senders" do
      context "send log in json" do
        
        let(:plugin) {
          LogStash::Outputs::SumoLogic.new(
            "url" => ENV["sumo_url"], 
            "sender_max" => 5,
            "interval" => 3,
            "format" => "%{@json}")
        }
        
        specify {
          5.times { |t| 
            event = LogStash::Event.new("host" => "myHost", "message" => "Hello world - #{t}")
            plugin.receive(event)
          } 
          expect { plugin.stats.total_output_requests.value }.to eventually(be > 0).within(10).pause_for(1)
          expect { plugin.stats.total_response("200") }.to eventually(be > 0).within(10).pause_for(1)
        }
      end
      context "send multiple log in json" do
        let(:plugin) {
          LogStash::Outputs::SumoLogic.new(
            "url" => ENV["sumo_url"], 
            "sender_max" => 5,
            "interval" => 3,
            "format" => "%{@json}"
          )
        }
        
        specify {
          5.times { |t| 
            events = 10.times.map { |r|
              LogStash::Event.new("host" => "myHost", "message" => "Hello world - #{t} - #{r}")
            }
            plugin.multi_receive(events)
          } 
          expect { plugin.stats.total_output_requests.value }.to eventually(be > 0).within(10).pause_for(1)
          expect { plugin.stats.total_response("200") }.to eventually(be > 0).within(10).pause_for(1)
        }
      end
    end
  end

  @@map = [('a'..'z'), ('A'..'Z')].map(&:to_a).flatten
  def get_line(length)
    length.times.map { @@map[rand(@@map.length)] }.join
  end

  context "throughput baseline" do
    let(:plugin) {
      LogStash::Outputs::SumoLogic.new(
        "url" => ENV["sumo_url"], 
        "source_category" => "logstash_ci_baseline",
        "sender_max" => 100,
        "interval" => 30,
        "format" => "%{@timestamp} %{message}",
        "compress" => true,
        "compress_encoding" => "gzip",
        "stats_enabled" => true,
        "stats_interval" => 1
      )
    }

    log_length = 5000 + rand(1000)
    log_count = 50000 + rand(10000)
  
    specify {
      log_count.times { |t| 
        event = LogStash::Event.new("message" => "#{t} - #{get_line(log_length)}")
        plugin.receive(event)
      } 
      expect { plugin.stats.total_log_lines.value }.to eventually(be >= log_count).within(60).pause_for(1)
      bytes = plugin.stats.total_output_bytes.value
      spend = (Time.now - plugin.stats.initialize_time) * 1000
      rate = bytes / spend * 1000
      puts "Sent #{plugin.stats.total_log_lines.value} log lines with #{bytes} bytes in #{'%.2f' % spend} ms, rate #{'%.2f' % (rate/1024/1024) } MB/s."
      expect(rate).to be > 2_000_000
    }
  end

end # describe
