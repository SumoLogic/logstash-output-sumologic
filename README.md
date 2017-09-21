# Logstash Sumo Logic Output Plugin

This is an output plugin for [Logstash](https://github.com/elastic/logstash).
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
bin/logstash -f samples/log.conf
```
The input from console will be sent to Sumo Logic cloud service as log lines.

Open samples/sample-metrics.conf, replace #URL# placeholder as real URL got from step 1
(This sample may require installing the [plugins-filters-metrics](https://www.elastic.co/guide/en/logstash/current/plugins-filters-metrics.html) plugin first)

Launch sample with:
```sh
bin/logstash -f samples/metrics.conf
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
| Parameter           | Type    | Required? | Default value | Decription            |
| ------------------- | ------- | --------- | ------------- | --------------------- |
| `url`               | string  | Yes       |               | HTTP Source URL
| `source_category`   | string  | No        |               | Source category to appear when searching in Sumo Logic by `_sourceCategory`. If not specified, the source category of the HTTP source will be used.
| `source_name`       | string  | No        |               | Source name to appear when searching in Sumo Logic by `_sourceName`.
| `source_host`       | string  | No        |               | Source host to appear when searching in Sumo Logic by `_sourceHost`. If not specified, it will be the machine host name.
| `extra_headers`     | hash    | No        |               | Extra fields need to be send in HTTP header.
| `compress`          | boolean | No        | `false`       | Enable or disable compression
| `compress_encoding` | string  | No        | `'deflate'`   | Encoding method of comressing, can only be `'deflate'` or `'gzip'`
| `interval`          | number  | No        | `0`           | The maximum time for waiting before send in batch, in ms. 
| `format`            | string  | No        | `"%{@timestamp} %{host} %{message}"` | For log only, the formatter of log lines. Use `%{@json}` as the placeholder for whole event json
| `json_mapping`      | hash    | No        |               | Override the structure of `{@json}` tag with the given key value pairs
| `metrics`           | hash    | No        |               | If defined, the event will be sent as metrics. Keys will be the metrics name and values will be the metrics value
| `metrics_format`    | string  | No        | `'cabon2'`    | Metrics format, can only be `'graphite'` or `'carbon2'`
| `metrics_name`      | string  | No        | `*`           | Define the metric name looking, the placeholder '*' will be replaced with the actual metric name
| `intrinsic_tags`    | hash    | No        |               | For carbon2 format only, send extra intrinsic key-value pairs other than `metric` (which is the metric name)
| `meta_tags`         | hash    | No        |               | For carbon2 format only, send metadata key-value pairs

This plugin is based on [logstash-mixin-http_client](https://github.com/logstash-plugins/logstash-mixin-http_client) thus we also support all HTTP layer parameters like proxy, authentication, retry, etc.

