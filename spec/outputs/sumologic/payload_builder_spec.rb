# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/outputs/sumologic"
require "logstash/event"

describe LogStash::Outputs::SumoLogic::PayloadBuilder do

  result = ""

  before :each do
    result = builder.build(event)
  end

  context "should build log payload in default format" do

    let(:builder) { LogStash::Outputs::SumoLogic::PayloadBuilder.new("url" => "http://localhost/1234") }
    let(:event) { LogStash::Event.new("host" => "myHost", "message" => "Hello world") }

    it "start with a valid timestamp" do
      ts = result.split(" ")[0]
      DateTime.parse(ts)
    end

    it "end with host and message" do
      expect(result).to end_with("myHost Hello world")
    end

  end # context
  
  context "should build log payload with @json tag" do

    let(:builder) { LogStash::Outputs::SumoLogic::PayloadBuilder.new("url" => "http://localhost/1234", "format" => "%{@json}") }
    let(:event) { LogStash::Event.new("host" => "myHost", "message" => "Hello world") }

    it "include host field" do
      expect(result).to include("\"host\":\"myHost\"")
    end

    it "include host field" do
      expect(result).to include("\"message\":\"Hello world\"")
    end

    it "include host field" do
      expect(result).to include("\"@timestamp\"")
    end

  end # context

  context "should build log payload with customized format" do

    let(:builder) { LogStash::Outputs::SumoLogic::PayloadBuilder.new("url" => "http://localhost/1234", "format" => "%{@timestamp} %{foo} %{bar}") }
    let(:event) { LogStash::Event.new("host" => "myHost", "foo" => "fancy", "bar" => 24) }

    it "start with a valid timestamp" do
      ts = result.split(" ")[0]
      DateTime.parse(ts)
    end

    it "end with host and message" do
      expect(result).to end_with("fancy 24")
    end

  end # context

  context "should build log payload with customized json_mapping" do

    let(:builder) { 
      LogStash::Outputs::SumoLogic::PayloadBuilder.new(
        "url" => "http://localhost/1234",
        "format" => "%{host} %{@json}",
        "json_mapping" => {
          "foo" => "%{foo}",
          "bar" => "%{bar}",
          "%{foo}" => "%{bar}"
        })
    }
    let(:event) { LogStash::Event.new("host" => "myHost", "foo" => "fancy", "bar" => 24) }

    specify {
      expect(result).to eq("myHost {\"foo\":\"fancy\",\"bar\":\"24\",\"fancy\":\"24\"}")
    }

  end # context

  context "should build metrics payload with graphite format" do

    let(:builder) {
      LogStash::Outputs::SumoLogic::PayloadBuilder.new(
        "url" => "http://localhost/1234",
        "metrics" => {
          "hurray.%{foo}" => "%{bar}"
        },
        "metrics_format" => "graphite")
    }
    let(:event) { LogStash::Event.new("host" => "myHost", "foo" => "fancy", "bar" => 24) }

    it "start with metrics name and value" do
      expect(result).to start_with("hurray.fancy 24 ")
    end

    it "end with epoch timestamp" do
      expect(result).to match(/\d{10,}$/)
    end

  end # context

  context "should build metrics payload with carbon2 format" do
    
    let(:builder) {
      LogStash::Outputs::SumoLogic::PayloadBuilder.new(
        "url" => "http://localhost/1234",
        "metrics" => {
          "hurray.%{foo}" => "%{bar}"
        })
    }
    let(:event) { LogStash::Event.new("host" => "myHost", "foo" => "fancy", "bar" => 24) }

    it "start with metrics name and value" do
      expect(result).to start_with("metric=hurray.fancy  24 ")
    end

    it "end with epoch timestamp" do
      expect(result).to match(/\d{10,}$/)
    end

  end # context

  context "should build metrics payload with metrics_name override" do
    
    let(:builder) {
      LogStash::Outputs::SumoLogic::PayloadBuilder.new(
        "url" => "http://localhost/1234",
        "metrics" => {
          "hurray.%{foo}" => "%{bar}"
        },
        "metrics_name" => "mynamespace.*")
    }
    let(:event) { LogStash::Event.new("host" => "myHost", "foo" => "fancy", "bar" => 24) }

    it "start with modified metrics name and value" do
      expect(result).to start_with("metric=mynamespace.hurray.fancy  24 ")
    end

    it "end with epoch timestamp" do
      expect(result).to match(/\d{10,}$/)
    end

  end # context

  context "should build metrics payload with intrinsic_tags override" do
    
    let(:builder) {
      LogStash::Outputs::SumoLogic::PayloadBuilder.new(
        "url" => "http://localhost/1234",
        "metrics" => {
          "bar" => "%{bar}"
        }, 
        "intrinsic_tags" => {
          "host" => "%{host}"
        })
    }
    let(:event) { LogStash::Event.new("host" => "myHost", "foo" => "fancy", "bar" => 24) }

    it "start with modified intrinsic tags and value" do
      expect(result).to start_with("host=myHost metric=bar  24 ")
    end

    it "end with epoch timestamp" do
      expect(result).to match(/\d{10,}$/)
    end

  end # context

  context "should build metrics payload with meta_tags override" do
    
    let(:builder) {
      LogStash::Outputs::SumoLogic::PayloadBuilder.new(
        "url" => "http://localhost/1234",
        "metrics" => {
          "bar" => "%{bar}"
        },
        "intrinsic_tags" => {
          "host" => "%{host}"
        },
        "meta_tags" => {
          "foo" => "%{foo}"
        })
    }
    let(:event) { LogStash::Event.new("host" => "myHost", "foo" => "fancy", "bar" => 24) }

    it "start with modified intrinsic/meta tags and value" do
      expect(result).to start_with("host=myHost metric=bar  foo=fancy 24 ")
    end

    it "end with epoch timestamp" do
      expect(result).to match(/\d{10,}$/)
    end

  end # context

  context "should build metrics payload with multi lines with different values (graphite)" do
    let(:builder) {
      LogStash::Outputs::SumoLogic::PayloadBuilder.new(
        "url" => "http://localhost/1234",
        "metrics" => {
          "cpu1" => "%{cpu1}",
          "cpu2" => "%{cpu2}"
        },
        "metrics_name" => "mynamespace.*",
        "metrics_format" => "graphite")
    }
    let(:event) { LogStash::Event.new("host" => "myHost", "foo" => "fancy", "cpu1" => 0.24, "cpu2" => 0.11) }

    specify {
      lines = result.split(/\n/).sort
      expect(lines.length).to eq(2)
      expect(lines.shift).to match(/^mynamespace\.cpu1 0\.24 \d{10,}$/)
      expect(lines.shift).to match(/^mynamespace\.cpu2 0\.11 \d{10,}$/)
    }
  
  end # context

  context "should build metrics payload with multi lines with different values (carbon2)" do
    
    let(:builder) {
      LogStash::Outputs::SumoLogic::PayloadBuilder.new(
        "url" => "http://localhost/1234",
        "metrics" => {
          "cpu1" => "%{cpu1}",
          "cpu2" => "%{cpu2}"
        },
        "intrinsic_tags" => {
          "host" => "%{host}"
        },
        "meta_tags" => {
          "foo" => "%{foo}"
        })
    }
    let(:event) { LogStash::Event.new("host" => "myHost", "foo" => "fancy", "cpu1" => 0.24, "cpu2" => 0.11) }

    specify {
      lines = result.split(/\n/).sort
      expect(lines.length).to eq(2)
      expect(lines.shift).to match(/^host=myHost metric=cpu1  foo=fancy 0\.24 \d{10,}$/)
      expect(lines.shift).to match(/^host=myHost metric=cpu2  foo=fancy 0\.11 \d{10,}$/)
    }
  
  end # context

  context "should build metrics payload with non-number value dropped (graphite)" do
    
    let(:builder) {
      LogStash::Outputs::SumoLogic::PayloadBuilder.new(
        "url" => "http://localhost/1234",
        "metrics" => {
          "cpu1" => "%{cpu1}",
          "cpu2" => "%{cpu2}",
          "cpu3" => "%{cpu3}"
        },
        "metrics_format" => "graphite")
    }
    let(:event) { LogStash::Event.new("host" => "myHost", "foo" => "fancy", "cpu1" => 0.24, "cpu2" => "abc", "cpu3" => 0.11) }

    it "include all points" do
      lines = result.split(/\n/).sort
      expect(lines.length).to eq(2)
      expect(lines.shift).to match(/^cpu1 0\.24 \d{10,}$/)
      expect(lines.shift).to match(/^cpu3 0\.11 \d{10,}$/)
    end
  
  end # context

  context "should build metrics payload with non-number value dropped (carbon2)" do
    
    let(:builder) {
      LogStash::Outputs::SumoLogic::PayloadBuilder.new(
        "url" => "http://localhost/1234",
        "metrics" => {
          "cpu1" => "%{cpu1}",
          "cpu2" => "%{cpu2}",
          "cpu3" => "%{cpu3}"
        },
        "intrinsic_tags" => {
          "host" => "%{host}"
        },
        "metrics_name" => "mynamespace.*",
        "meta_tags" => {
          "foo" => "%{foo}"
        })
    }
    let(:event) { LogStash::Event.new("host" => "myHost", "foo" => "fancy", "cpu1" => 0.24, "cpu2" => "abc", "cpu3" => 0.11) }

    specify {
      lines = result.split(/\n/).sort
      expect(lines.length).to eq(2)
      expect(lines.shift).to match(/^host=myHost metric=mynamespace\.cpu1  foo=fancy 0\.24 \d{10,}$/)
      expect(lines.shift).to match(/^host=myHost metric=mynamespace\.cpu3  foo=fancy 0\.11 \d{10,}$/)
    }

  end # context

  context "should build metrics payload with fields_as_metrics (graphite)" do
    
    let(:builder) {
      LogStash::Outputs::SumoLogic::PayloadBuilder.new(
        "url" => "http://localhost/1234",
        "fields_as_metrics" => true,
        "metrics_format" => "graphite")
    }
    let(:event) {
      LogStash::Event.new(
        "host" => "myHost",
        "foo" => "fancy",
        "cpu" => [0.24, 0.11, 0.75, 0.28],
        "storageRW" => 51,
        "bar" => "blahblah",
        "blkio" => {
          "write_ps" => 0,
          "read_ps" => 0,
          "total_ps" => 0
        })
    }

    specify {
      lines = result.split(/\n/).sort
      expect(lines.length).to eq(8)
      expect(lines.shift).to match(/^blkio\.read_ps 0 \d{10,}$/)
      expect(lines.shift).to match(/^blkio\.total_ps 0 \d{10,}$/)
      expect(lines.shift).to match(/^blkio\.write_ps 0 \d{10,}$/)
      expect(lines.shift).to match(/^cpu\.0 0\.24 \d{10,}$/)
      expect(lines.shift).to match(/^cpu\.1 0\.11 \d{10,}$/)
      expect(lines.shift).to match(/^cpu\.2 0\.75 \d{10,}$/)
      expect(lines.shift).to match(/^cpu\.3 0\.28 \d{10,}$/)
      expect(lines.shift).to match(/^storageRW 51 \d{10,}$/)
    }

  end # context

  context "should build metrics payload with fields_as_metrics (carbon2)" do
    
    let(:builder) {
      LogStash::Outputs::SumoLogic::PayloadBuilder.new(
        "url" => "http://localhost/1234",
        "fields_as_metrics" => true,
        "intrinsic_tags" => {
          "host"=>"%{host}"
        },
        "meta_tags" => {
          "foo" => "%{foo}"
        })
    }
    let(:event) {
      LogStash::Event.new(
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
    }

    specify {
      lines = result.split(/\n/).sort
      expect(lines.length).to eq(8)
      expect(lines.shift).to match(/^host=myHost metric=blkio\.read_ps  foo=fancy 2 \d{10,}$/)
      expect(lines.shift).to match(/^host=myHost metric=blkio\.total_ps  foo=fancy 0 \d{10,}$/)
      expect(lines.shift).to match(/^host=myHost metric=blkio\.write_ps  foo=fancy 5 \d{10,}$/)
      expect(lines.shift).to match(/^host=myHost metric=cpu\.0  foo=fancy 0\.24 \d{10,}$/)
      expect(lines.shift).to match(/^host=myHost metric=cpu\.1  foo=fancy 0\.11 \d{10,}$/)
      expect(lines.shift).to match(/^host=myHost metric=cpu\.2  foo=fancy 0\.75 \d{10,}$/)
      expect(lines.shift).to match(/^host=myHost metric=cpu\.3  foo=fancy 0\.28 \d{10,}$/)
      expect(lines.shift).to match(/^host=myHost metric=storageRW  foo=fancy 51 \d{10,}$/)
    }

  end # context

  context "should hornor fields_include when fields_as_metrics (graphite)" do
    
    let(:builder) {
      LogStash::Outputs::SumoLogic::PayloadBuilder.new(
        "url" => "http://localhost/1234",
        "fields_as_metrics" => true,
        "metrics_format" => "graphite",
        "fields_include" => ["cpu*"])
      }
    let(:event) {
      LogStash::Event.new(
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
      }

    specify {
      lines = result.split(/\n/).sort
      expect(lines.length).to eq(4)
      expect(lines.shift).to match(/^cpu\.0 0\.24 \d{10,}$/)
      expect(lines.shift).to match(/^cpu\.1 0\.11 \d{10,}$/)
      expect(lines.shift).to match(/^cpu\.2 0\.75 \d{10,}$/)
      expect(lines.shift).to match(/^cpu\.3 0\.28 \d{10,}$/)
    }

  end # context

  context "should hornor fields_include when fields_as_metrics (carbon2)" do
    
    let(:builder) {
      LogStash::Outputs::SumoLogic::PayloadBuilder.new(
        "url" => "http://localhost/1234",
        "fields_as_metrics" => true,
        "intrinsic_tags" => {
          "host" => "%{host}"
        },
        "meta_tags" => {
          "foo" => "%{foo}"
        },
        "fields_include" => ["cpu*"])
      }
    let(:event) {
      LogStash::Event.new(
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
      }

    specify {
      lines = result.split(/\n/).sort
      expect(lines.length).to eq(4)
      expect(lines.shift).to match(/^host=myHost metric=cpu\.0  foo=fancy 0\.24 \d{10,}$/)
      expect(lines.shift).to match(/^host=myHost metric=cpu\.1  foo=fancy 0\.11 \d{10,}$/)
      expect(lines.shift).to match(/^host=myHost metric=cpu\.2  foo=fancy 0\.75 \d{10,}$/)
      expect(lines.shift).to match(/^host=myHost metric=cpu\.3  foo=fancy 0\.28 \d{10,}$/)
    }

  end # context

  context "should hornor fields_exclude when fields_as_metrics (graphite)" do
    
    let(:builder) {
      LogStash::Outputs::SumoLogic::PayloadBuilder.new(
        "url" => "http://localhost/1234",
        "fields_as_metrics" => true,
        "metrics_format" => "graphite",
        "fields_include" => ["cpu*"],
        "fields_exclude" => [".*1"])
      }
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

    specify {
      lines = result.split(/\n/).sort
      expect(lines.length).to eq(3)
      expect(lines.shift).to match(/^cpu\.0 0\.24 \d{10,}$/)
      expect(lines.shift).to match(/^cpu\.2 0\.75 \d{10,}$/)
      expect(lines.shift).to match(/^cpu\.3 0\.28 \d{10,}$/)
    }

  end # context

  context "should hornor fields_exclude when fields_as_metrics (carbon2)" do
    
    let(:builder) {
      LogStash::Outputs::SumoLogic::PayloadBuilder.new(
        "url" => "http://localhost/1234",
        "fields_as_metrics" => true,
        "intrinsic_tags" => {
          "host" => "%{host}"
        },
        "meta_tags" => {
          "foo" => "%{foo}"
        },
        "fields_include" => ["cpu*"],
        "fields_exclude" => [".*1"])
      }
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

    specify {
      lines = result.split(/\n/).sort
      expect(lines.length).to eq(3)
      expect(lines.shift).to match(/^host=myHost metric=cpu\.0  foo=fancy 0\.24 \d{10,}$/)
      expect(lines.shift).to match(/^host=myHost metric=cpu\.2  foo=fancy 0\.75 \d{10,}$/)
      expect(lines.shift).to match(/^host=myHost metric=cpu\.3  foo=fancy 0\.28 \d{10,}$/)
    }
    
  end # context

end # describe
