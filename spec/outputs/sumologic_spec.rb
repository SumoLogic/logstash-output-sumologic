# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/outputs/sumologic"
require "logstash/event"

require_relative '../spec_helper'

describe LogStash::Outputs::SumoLogic do

  let(:server) { subject.server }
  
  before :each do
    subject.register
    subject.receive(event)
  end

  # For log
  context "log sent in default format" do

    subject { LogStash::Outputs::SumoLogic.new("url" => "http://localhost/1234") }
    let(:event) { LogStash::Event.new("host" => "myHost", "message" => "Hello world") }

    it "generate one element" do
      expect(server.size).to eq(1)
    end

    it "include all content" do
      expect(server.pop).to include("myHost Hello world")
    end

  end

  context "log sent as @json" do

    subject { LogStash::Outputs::SumoLogic.new("url" => "http://localhost/1234", "format" => "%{@json}") }
    let(:event) { LogStash::Event.new("host" => "myHost", "message" => "Hello world") }

    it "generate one element" do
      expect(server.size).to eq(1)
    end

    it "include all content" do
      received = server.pop
      expect(received).to include("\"host\":\"myHost\"")
      expect(received).to include("\"message\":\"Hello world\"")
    end

  end

  context "log sent in customized format" do

    subject { LogStash::Outputs::SumoLogic.new("url" => "http://localhost/1234", "format" => "%{foo} %{bar}" ) }
    let(:event) { LogStash::Event.new("host" => "myHost", "foo" => "fancy", "bar" => 24) }

    it "generate one element" do
      expect(server.size).to eq(1)
    end

    it "include all content" do
      expect(server.pop).to eq("fancy 24")
    end

  end

  context "log sent with customized json_mapping" do

    subject { LogStash::Outputs::SumoLogic.new("url" => "http://localhost/1234", 
					       "format" => "%{host} %{@json}", 
					       "json_mapping" => { "foo" => "%{foo}", "bar" => "%{bar}", "%{foo}" => "%{bar}" } ) }
    let(:event) { LogStash::Event.new("host" => "myHost", "foo" => "fancy", "bar" => 24) }

    it "generate one element" do
      expect(server.size).to eq(1)
    end

    it "include all content" do
      expect(server.pop).to eq("myHost {\"foo\":\"fancy\",\"bar\":\"24\",\"fancy\":\"24\"}")
    end

  end

  # For headers
  context "check default headers" do

    subject { LogStash::Outputs::SumoLogic.new("url" => "http://localhost/1234") }
    let(:event) { LogStash::Event.new("host" => "myHost", "message" => "Hello world") }

    it "check header" do
      expect(server.header).to eq({"X-Sumo-Host"=>`hostname`.strip, "X-Sumo-Client"=>"logstash-output-sumologic", "Content-Type"=>"text/plain"})
    end

  end

  context "override source_category" do
    
    subject { LogStash::Outputs::SumoLogic.new("url" => "http://localhost/1234", "source_category" => "my source category") }
    let(:event) { LogStash::Event.new("host" => "myHost", "message" => "Hello world") }

    it "check header" do
      expect(server.header).to eq({"X-Sumo-Host"=>`hostname`.strip, 
				   "X-Sumo-Client"=>"logstash-output-sumologic", 
				   "Content-Type"=>"text/plain", 
				   "X-Sumo-Category"=>"my source category"})
    end

  end

  context "override source_name" do
    
    subject { LogStash::Outputs::SumoLogic.new("url" => "http://localhost/1234", "source_name" => "my source name") }
    let(:event) { LogStash::Event.new("host" => "myHost", "message" => "Hello world") }

    it "check header" do
      expect(server.header).to eq({"X-Sumo-Host"=>`hostname`.strip, 
				   "X-Sumo-Client"=>"logstash-output-sumologic", 
				   "Content-Type"=>"text/plain", 
				   "X-Sumo-Name"=>"my source name"})
    end

  end

  context "override source_host" do
    
    subject { LogStash::Outputs::SumoLogic.new("url" => "http://localhost/1234", "source_host" => "my source host") }
    let(:event) { LogStash::Event.new("host" => "myHost", "message" => "Hello world") }

    it "check header" do
      expect(server.header).to eq({"X-Sumo-Host"=>"my source host", "X-Sumo-Client"=>"logstash-output-sumologic", "Content-Type"=>"text/plain"})
    end

  end

  context "with extra_headers" do
    
    subject { LogStash::Outputs::SumoLogic.new("url" => "http://localhost/1234", "extra_headers" => {"foo" => "bar"}) }
    let(:event) { LogStash::Event.new("host" => "myHost", "message" => "Hello world") }

    it "check header" do
      expect(server.header).to eq({"X-Sumo-Host"=>`hostname`.strip, "X-Sumo-Client"=>"logstash-output-sumologic", "Content-Type"=>"text/plain", "foo"=>"bar"})
    end

  end

  context "with compress" do
    
    subject { LogStash::Outputs::SumoLogic.new("url" => "http://localhost/1234", "compress" => true) }
    let(:event) { LogStash::Event.new("host" => "myHost", "message" => "Hello world") }

    it "check header" do
      expect(server.header).to eq({"X-Sumo-Host"=>`hostname`.strip, 
				   "X-Sumo-Client"=>"logstash-output-sumologic", 
				   "Content-Type"=>"text/plain", 
				   "Content-Encoding"=>"deflate"})
    end

  end

  context "with gzip" do
    
    subject { LogStash::Outputs::SumoLogic.new("url" => "http://localhost/1234", "compress" => true, "compress_encoding"=>"gzip") }
    let(:event) { LogStash::Event.new("host" => "myHost", "message" => "Hello world") }

    it "check header" do
      expect(server.header).to eq({"X-Sumo-Host"=>`hostname`.strip, 
				   "X-Sumo-Client"=>"logstash-output-sumologic", 
				   "Content-Type"=>"text/plain", 
				   "Content-Encoding"=>"gzip"})
    end

  end

  # For metrics
  context "with metrics sent in graphite" do

    subject { LogStash::Outputs::SumoLogic.new("url" => "http://localhost/1234", 
					       "metrics" => { "hurray.%{foo}" => "%{bar}"}, 
					       "metrics_format" => "graphite") }
    let(:event) { LogStash::Event.new("host" => "myHost", "foo" => "fancy", "bar" => 24) }

    it "generate one element" do
      expect(server.size).to eq(1)
    end

    it "check header" do
      expect(server.header).to eq({"X-Sumo-Host"=>`hostname`.strip, 
				   "X-Sumo-Client"=>"logstash-output-sumologic", 
				   "Content-Type"=>"application/vnd.sumologic.graphite"})
    end

    it "include all content" do
      expect(server.pop).to match(/^hurray.fancy 24 \d{10,}$/)
    end

  end

  context "with metrics sent in carbon2" do
    subject { LogStash::Outputs::SumoLogic.new("url" => "http://localhost/1234", "metrics" => { "hurray.%{foo}" => "%{bar}" }) }
    let(:event) { LogStash::Event.new("host" => "myHost", "foo" => "fancy", "bar" => 24) }

    it "generate one element" do
      expect(server.size).to eq(1)
    end

    it "check header" do
      expect(server.header).to eq({"X-Sumo-Host"=>`hostname`.strip, 
				   "X-Sumo-Client"=>"logstash-output-sumologic", 
				   "Content-Type"=>"application/vnd.sumologic.carbon2"})
    end

    it "include all content" do
      expect(server.pop).to match(/^metric=hurray.fancy  24 \d{10,}$/)
    end
  end

  context "with metrics_name override" do
    subject { LogStash::Outputs::SumoLogic.new("url" => "http://localhost/1234", 
					       "metrics" => { "hurray.%{foo}" => "%{bar}" }, 
					       "metrics_name" => "mynamespace.*") }
    let(:event) { LogStash::Event.new("host" => "myHost", "foo" => "fancy", "bar" => 24) }

    it "include all content" do
      expect(server.pop).to match(/^metric=mynamespace.hurray.fancy  24 \d{10,}$/)
    end
  end

  context "with intrinsic_tags override" do
    subject { LogStash::Outputs::SumoLogic.new("url" => "http://localhost/1234", 
					       "metrics" => { "bar" => "%{bar}" }, 
					       "intrinsic_tags" => {"host"=>"%{host}"}) }
    let(:event) { LogStash::Event.new("host" => "myHost", "foo" => "fancy", "bar" => 24) }

    it "include all content" do
      expect(server.pop).to match(/^host=myHost metric=bar  24 \d{10,}$/)
    end
  end

  context "with meta_tags override" do
    subject { LogStash::Outputs::SumoLogic.new("url" => "http://localhost/1234", 
					       "metrics" => { "bar" => "%{bar}" }, 
					       "intrinsic_tags" => {"host"=>"%{host}"}, 
					       "meta_tags" => {"foo" => "%{foo}"}) }
    let(:event) { LogStash::Event.new("host" => "myHost", "foo" => "fancy", "bar" => 24) }

    it "include all content" do
      expect(server.pop).to match(/^host=myHost metric=bar  foo=fancy 24 \d{10,}$/)
    end
  end

  context "with multiple metrics mapping" do
    subject { LogStash::Outputs::SumoLogic.new("url" => "http://localhost/1234", 
					       "metrics" => { "cpu1" => "%{cpu1}", "cpu2" => "%{cpu2}" }, 
					       "intrinsic_tags" => {"host"=>"%{host}"}, 
					       "meta_tags" => {"foo" => "%{foo}"}) }
    let(:event) { LogStash::Event.new("host" => "myHost", "foo" => "fancy", "cpu1" => 0.24, "cpu2" => 0.11) }

    it "include content" do
      sorted = server.all_sorted
      expect(sorted.pop).to match(/^host=myHost metric=cpu1  foo=fancy 0\.24 \d{10,}$/)
      expect(sorted.pop).to match(/^host=myHost metric=cpu2  foo=fancy 0\.11 \d{10,}$/)
    end
  end

  context "metrics with non-number value should be dropped (carbon2)" do
    subject { LogStash::Outputs::SumoLogic.new("url" => "http://localhost/1234", 
					       "metrics" => { "cpu1" => "%{cpu1}", "cpu2" => "%{cpu2}", "cpu3" => "%{cpu3}" }, 
					       "intrinsic_tags" => {"host"=>"%{host}"}, "meta_tags" => {"foo" => "%{foo}"}) }
    let(:event) { LogStash::Event.new("host" => "myHost", "foo" => "fancy", "cpu1" => 0.24, "cpu2" => "abc", "cpu3" => 0.11) }

    it "include content" do
      sorted = server.all_sorted
      expect(sorted.pop).to match(/^host=myHost metric=cpu1  foo=fancy 0\.24 \d{10,}$/)
      expect(sorted.pop).to match(/^host=myHost metric=cpu3  foo=fancy 0\.11 \d{10,}$/)
      expect(sorted.empty?).to eq(true)
    end
  end

  context "metrics with non-number value should be dropped (graphite)" do
    subject { LogStash::Outputs::SumoLogic.new("url" => "http://localhost/1234", 
					       "metrics" => { "cpu1" => "%{cpu1}", "cpu2" => "%{cpu2}", "cpu3" => "%{cpu3}" }, 
					       "metrics_format" => "graphite") }
    let(:event) { LogStash::Event.new("host" => "myHost", "foo" => "fancy", "cpu1" => 0.24, "cpu2" => "abc", "cpu3" => 0.11) }

    it "include content" do
      sorted = server.all_sorted
      expect(sorted.pop).to match(/^cpu1 0\.24 \d{10,}$/)
      expect(sorted.pop).to match(/^cpu3 0\.11 \d{10,}$/)
      expect(sorted.empty?).to eq(true)
    end
  end

  context "fields_as_metrics (carbon2)" do
    subject { LogStash::Outputs::SumoLogic.new("url" => "http://localhost/1234", 
					       "fields_as_metrics" => true, 
					       "intrinsic_tags" => {"host"=>"%{host}"}, 
					       "meta_tags" => {"foo" => "%{foo}"}) }
    let(:event) { LogStash::Event.new(
      "host" => "myHost", 
      "foo" => "fancy", 
      "cpu" => [0.24, 0.11, 0.75, 0.28], 
      "storageRW" => 51, 
      "bar" => "blahblah", 
      "blkio" => {
        "write_ps" => 5,
        "read_ps" => 2,
        "total_ps" => 0
      })}

    it "include content" do
      sorted = server.all_sorted
      expect(sorted.pop).to match(/^host=myHost metric=blkio\.read_ps  foo=fancy 2 \d{10,}$/)
      expect(sorted.pop).to match(/^host=myHost metric=blkio\.total_ps  foo=fancy 0 \d{10,}$/)
      expect(sorted.pop).to match(/^host=myHost metric=blkio\.write_ps  foo=fancy 5 \d{10,}$/)
      expect(sorted.pop).to match(/^host=myHost metric=cpu\.0  foo=fancy 0\.24 \d{10,}$/)
      expect(sorted.pop).to match(/^host=myHost metric=cpu\.1  foo=fancy 0\.11 \d{10,}$/)
      expect(sorted.pop).to match(/^host=myHost metric=cpu\.2  foo=fancy 0\.75 \d{10,}$/)
      expect(sorted.pop).to match(/^host=myHost metric=cpu\.3  foo=fancy 0\.28 \d{10,}$/)
      expect(sorted.pop).to match(/^host=myHost metric=storageRW  foo=fancy 51 \d{10,}$/)
      expect(sorted.empty?).to eq(true)
    end
  end

  context "fields_as_metrics (graphite)" do
    subject { LogStash::Outputs::SumoLogic.new("url" => "http://localhost/1234", "fields_as_metrics" => true, "metrics_format" => "graphite") }
    let(:event) { LogStash::Event.new(
      "host" => "myHost", 
      "foo" => "fancy", 
      "cpu" => [0.24, 0.11, 0.75, 0.28], 
      "storageRW" => 51, 
      "bar" => "blahblah", 
      "blkio" => {
        "write_ps" => 0,
        "read_ps" => 0,
        "total_ps" => 0
      })}

    it "include content" do
      sorted = server.all_sorted
      expect(sorted.pop).to match(/^blkio\.read_ps 0 \d{10,}$/)
      expect(sorted.pop).to match(/^blkio\.total_ps 0 \d{10,}$/)
      expect(sorted.pop).to match(/^blkio\.write_ps 0 \d{10,}$/)
      expect(sorted.pop).to match(/^cpu\.0 0\.24 \d{10,}$/)
      expect(sorted.pop).to match(/^cpu\.1 0\.11 \d{10,}$/)
      expect(sorted.pop).to match(/^cpu\.2 0\.75 \d{10,}$/)
      expect(sorted.pop).to match(/^cpu\.3 0\.28 \d{10,}$/)
      expect(sorted.pop).to match(/^storageRW 51 \d{10,}$/)
    end
  end

  context "fields_include is honored when fields_as_metrics (carbon2)" do
    subject { LogStash::Outputs::SumoLogic.new("url" => "http://localhost/1234", 
					       "fields_as_metrics" => true, 
					       "intrinsic_tags" => {"host"=>"%{host}"}, 
					       "meta_tags" => {"foo" => "%{foo}"}, 
					       "fields_include" => ["cpu*"]) }
    let(:event) { LogStash::Event.new(
      "host" => "myHost", 
      "foo" => "fancy", 
      "cpu" => [0.24, 0.11, 0.75, 0.28], 
      "storageRW" => 51, 
      "bar" => "blahblah", 
      "blkio" => {
        "write_ps" => 5,
        "read_ps" => 2,
        "total_ps" => 0
      })}

    it "include content" do
      sorted = server.all_sorted
      expect(sorted.pop).to match(/^host=myHost metric=cpu\.0  foo=fancy 0\.24 \d{10,}$/)
      expect(sorted.pop).to match(/^host=myHost metric=cpu\.1  foo=fancy 0\.11 \d{10,}$/)
      expect(sorted.pop).to match(/^host=myHost metric=cpu\.2  foo=fancy 0\.75 \d{10,}$/)
      expect(sorted.pop).to match(/^host=myHost metric=cpu\.3  foo=fancy 0\.28 \d{10,}$/)
      expect(sorted.empty?).to eq(true)
    end
  end

  context "fields_exclude is honored when fields_as_metrics (carbon2)" do
    subject { LogStash::Outputs::SumoLogic.new("url" => "http://localhost/1234", 
					       "fields_as_metrics" => true, 
					       "intrinsic_tags" => {"host"=>"%{host}"}, 
					       "meta_tags" => {"foo" => "%{foo}"}, 
					       "fields_include" => ["cpu*"], 
					       "fields_exclude" => [".*1"]) }
    let(:event) { LogStash::Event.new(
      "host" => "myHost", 
      "foo" => "fancy", 
      "cpu" => [0.24, 0.11, 0.75, 0.28], 
      "storageRW" => 51, 
      "bar" => "blahblah", 
      "blkio" => {
        "write_ps" => 5,
        "read_ps" => 2,
        "total_ps" => 0
      })}

    it "include content" do
      sorted = server.all_sorted
      expect(sorted.pop).to match(/^host=myHost metric=cpu\.0  foo=fancy 0\.24 \d{10,}$/)
      expect(sorted.pop).to match(/^host=myHost metric=cpu\.2  foo=fancy 0\.75 \d{10,}$/)
      expect(sorted.pop).to match(/^host=myHost metric=cpu\.3  foo=fancy 0\.28 \d{10,}$/)
      expect(sorted.empty?).to eq(true)
    end
  end

end
