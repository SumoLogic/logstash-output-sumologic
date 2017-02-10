# Logstash Sumo Logic Output Plugin

This is a plugin for [Logstash](https://github.com/elastic/logstash).
It is fully free and fully open source. The license is Apache 2.0, meaning you are pretty much free to use it however you want in whatever way.

## Getting Started

### 1. Create a Sumo Logic HTTP source
Create a [Sumo Logic](https://www.sumologic.com/) free account if you currently don't have one.

Create a [HTTP source](http://help.sumologic.com/Send_Data/Sources/HTTP_Source) in your account and get the URL for this source. It should be something like:
```
https://events.sumologic.net/receiver/v1/http/XXXXXXXXXX
```

### 2. Install LogStash on your machine
Following this [instruction](https://www.elastic.co/guide/en/logstash/current/getting-started-with-logstash.html) to download and install LogStash. This plugin requires Logstash 2.3 or higher to work.

### 3. Build your plugin gem
In your local Git clone, running:
```sh
gem build logstash-output-sumologic.gemspec
```
You will get a .gem file as `logstash-output-sumologic-1.0.0.gem`

### 4. Install plugin into LogStash
In the Logstash home, running:
```sh
bin/logstash-plugin install <path of .gem>
```

### 5. Start Logstash and send log
In the Logstash home, running:
```sh
bin/logstash -e 'input{stdin{}}output{sumologic{url=>"<url from step 1>"}}'
```
This will send any input from console to Sumo Logic cloud service.

### 6. Get result from Sumo Logic web app
Logon to Sumo Logic [web app](https://prod-www.sumologic.net/ui/) and run [Search](http://help.sumologic.com/Search) or [Live Tail](http://help.sumologic.com/Search/Live_Tail)

### Furthermore
- Try it with different input/filter/codec plugins
- Start LogStash as a service/daemon in your production environment
- Report any issue or idea through [Git Hub](https://github.com/SumoLogic/logstash-output-sumologic)

## Parameters
This plugin is based on [logstash-mixin-http_client](https://github.com/logstash-plugins/logstash-mixin-http_client) thus it supports all parameters like proxy, authentication, retry, etc.

And it supports following additional prarmeters:
```
  # The URL to send logs to. This should be given when creating a HTTP Source
  # on Sumo Logic web app. See http://help.sumologic.com/Send_Data/Sources/HTTP_Source
  config :url, :validate => :string, :required => true

  # Include extra HTTP headers on request if needed
  config :extra_headers, :validate => :hash, :default => []

  # The formatter of message, by default is message with timestamp and host as prefix
  config :format, :validate => :string, :default => "%{@timestamp} %{host} %{message}"

  # Hold messages for at least (x) seconds as a pile; 0 means sending every events immediately  
  config :interval, :validate => :number, :default => 0

  # Compress the payload
  config :compress, :validate => :boolean, :default => false

```
