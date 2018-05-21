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
          expect { plugin.stats.total_request.value }.to eventually(be > 0).within(10).pause_for(1)
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
          expect { plugin.stats.total_request.value }.to eventually(be > 0).within(10).pause_for(1)
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
          50.times { |t| 
            event = LogStash::Event.new("host" => "myHost", "message" => "Hello world - #{t}")
            plugin.receive(event)
          } 
          expect { plugin.stats.total_request.value }.to eventually(be > 0).within(10).pause_for(1)
          expect { plugin.stats.total_response("200") }.to eventually(be > 0).within(10).pause_for(1)
        }
      end

      context "send multiple log in json" do
        
        let(:plugin) {
          LogStash::Outputs::SumoLogic.new(
            "url" => ENV["sumo_url"], 
            "sender_max" => 5,
            "format" => "%{@json}")
        }
        
        specify {
          50.times { |t| 
            events = 10.times.map { |r|
              LogStash::Event.new("host" => "myHost", "message" => "Hello world - #{t} - #{r}")
            }
            plugin.multi_receive(events)
          } 
          expect { plugin.stats.total_request.value }.to eventually(be > 0).within(10).pause_for(1)
          expect { plugin.stats.total_response("200") }.to eventually(be > 0).within(10).pause_for(1)
        }
      end

    end
  end

  context "has pile" do
    context "single senders" do
    end
  end

end # describe
