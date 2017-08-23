# Logstash Sumo Logic Output Plugin

This is a plugin for [Logstash](https://github.com/elastic/logstash).
It is fully free and fully open source. The license is Apache 2.0, meaning you are pretty much free to use it however you want in whatever way.

## Getting Started
This guide is for the users just want download the binary and make the plugin work. For the developer, please refer to the [Developer Guide](DEVELOPER.md)

### 1. Create a Sumo Logic HTTP source
Create a [Sumo Logic](https://www.sumologic.com/) free account if you currently don't have one.

Create a [HTTP source](http://help.sumologic.com/Send_Data/Sources/HTTP_Source) in your account and get the URL for this source. It should be something like:
```
https://events.sumologic.net/receiver/v1/http/XXXXXXXXXX
```

### 2. Install LogStash on your machine
Following this [instruction](https://www.elastic.co/guide/en/logstash/current/getting-started-with-logstash.html) to download and install LogStash. This plugin requires Logstash 2.3 or higher to work.

### 3. Install latest Logstash Sumo Logic Output plugin from [RubyGems](https://rubygems.org/gems/logstash-output-sumologic)
```sh
bin/logstash-plugin install logstash-output-sumologic
```
### 4. Start Logstash and send log
In the Logstash home, running:
```sh
bin/logstash -e 'input{stdin{}}output{sumologic{url=>"<URL from step 1>"}}'
```
This will send any input from console to Sumo Logic cloud service.

### 5. Try out samples
Open samples/sample-logs.conf, replace #URL# placeholder as real URL got from step 1
Launch sample with:
```sh
bin/logstash -f samples/sample-logs.conf
```
The input from console will be sent to Sumo Logic cloud service as log lines.

Open samples/sample-metrics.conf, replace #URL# placeholder as real URL got from step 1
(This sample may require install [plugins-filters-metrics](https://www.elastic.co/guide/en/logstash/current/plugins-filters-metrics.html) first)
Launch sample with:
```sh
bin/logstash -f samples/sample-metrics.conf
```
A mocked event will be sent to Sumo Logic cloud service as 1 minute and 15 minutes rate metrics.

### 6. Get result from Sumo Logic web app
Logon to Sumo Logic [web app](https://prod-www.sumologic.net/ui/) and run 
 - [Log Search](http://help.sumologic.com/Search)
 - [Live Tail](http://help.sumologic.com/Search/Live_Tail)
 - [Metrics Search](https://help.sumologic.com/Metrics)

## What's Next
- Try it with different input/filter/codec plugins
- Start LogStash as a service/daemon in your production environment 
- Report any issue or idea through [Git Hub](https://github.com/SumoLogic/logstash-output-sumologic)

## Parameters of Plugin
This plugin is based on [logstash-mixin-http_client](https://github.com/logstash-plugins/logstash-mixin-http_client) thus it supports all parameters like proxy, authentication, retry, etc.

And it supports following additional prarmeters:
```ruby
  # The URL to send logs to. This should be given when creating a HTTP Source
  # on Sumo Logic web app. See http://help.sumologic.com/Send_Data/Sources/HTTP_Source
  config :url, :validate => :string, :required => true

  # This lets you pre populate the structure and parts from the event into @json tag
  config :json_mapping, :validate => :hash

  # Define the source category metadata
  config :source_category, :validate => :string, :default => "logstash"

  # Define the source host metadata
  config :source_host, :validate => :string

  # Define the source name metadat
  config :source_name, :validate => :string

  # Include extra HTTP headers on request if needed 
  config :extra_headers, :validate => :hash

  # Compress the payload 
  config :compress, :validate => :boolean, :default => false

  # The encoding method of compress
  config :compress_encoding, :validate =>:string, :default => "defalte"

  # Hold messages for at least (x) seconds as a pile; 0 means sending every events immediately  
  config :interval, :validate => :number, :default => 0

  # The formatter of log message, by default is message with timestamp and host as prefix
  # use %{@json} tag to send whole event
  config :format, :validate => :string, :default => "%{@timestamp} %{host} %{message}"

  # Send metric(s) if configured. This is a hash with k as metric name and v as metric value
  # Both metric names and values support dynamic strings like %{host}
  # For example: 
  #     metrics => { "%{host}/uptime" => "%{uptime_1m}" }
  config :metrics, :validate => :hash
  
  # Defines the format of the metric, support "graphite" or "carbon2"
  config :metrics_format, :validate => :string, :default => "graphite"

  # Define the metric name looking, the placeholder '*' will be replaced with the actual metric name
  # For example:
  #     metrics => { "uptime.1m" => "%{uptime_1m}" }
  #     metrics_name => "mynamespace.*"
  # will produce metrics as:
  #     "mynamespace.uptime.1m xxx 1234567"
  config :metrics_name, :validate => :string, :default => "*"

  # For carbon2 metrics format only, define the intrinsic tags (which will be used to identify the metrics)
  # There is always an intrinsic tag as "name" => <metrics name>
  config :metrics_intrinsic_tags, :validate => :hash

  # For carbon2 metrics format only, define the meta tags (which will NOT be used to identify the metrics)
  # source_category, source_host and source_name will be passed in if exist
  config :metrics_meta_tags, :validate => :hash

```




