# Logstash Sumo Logic Output Plugin

[![Build Status](https://travis-ci.org/SumoLogic/logstash-output-sumologic.svg?branch=master)](https://travis-ci.org/SumoLogic/logstash-output-sumologic)  [![Gem Version](https://badge.fury.io/rb/logstash-output-sumologic.svg)](https://badge.fury.io/rb/logstash-output-sumologic)

This is an output plugin for [Logstash](https://github.com/elastic/logstash).
It is fully free and fully open source. The license is Apache 2.0, meaning you are pretty much free to use it however you want in whatever way.

## Getting Started

This guide is for the users just want to download the binary and make the plugin work. For the developer, please refer to the [Developer Guide](DEVELOPER.md)

### 1. Create a Sumo Logic HTTP source

Create a [Sumo Logic](https://www.sumologic.com/) free account if you currently don't have one.

Create a [HTTP source](http://help.sumologic.com/Send_Data/Sources/HTTP_Source) in your account and get the URL for this source. It should be something like:
`https://events.sumologic.net/receiver/v1/http/XXXXXXXXXX`

### 2. Install LogStash on your machine

Following this [instruction](https://www.elastic.co/guide/en/logstash/current/getting-started-with-logstash.html) to download and install LogStash. This plugin requires Logstash 2.3 or higher to work.

### 3. Install latest Logstash Sumo Logic Output plugin from [RubyGems](https://rubygems.org/gems/logstash-output-sumologic)

```bash
bin/logstash-plugin install logstash-output-sumologic
```

### 4. Start Logstash and send log

In the Logstash home, running:

```bash
bin/logstash -e "input{stdin{}}output{sumologic{url=>'<URL from step 1>'}}"
```

This will send any input from console to Sumo Logic cloud service.

### 5. Try out samples

#### Send Log lines

Set the URL got from step 1 as environment variable:

```bash
export sumo_url=https://events.sumologic.net/receiver/v1/http/XXXXXXXXXX
```

Launch sample with:

```bash
bin/logstash -f samples/log.conf
```

The input from console will be sent to Sumo Logic cloud service as log lines.

#### Send Metrics

Set the URL got from step 1 as environment variable:

```bash
export sumo_url=https://events.sumologic.net/receiver/v1/http/XXXXXXXXXX
```

Install [plugins-filters-metrics](https://www.elastic.co/guide/en/logstash/current/plugins-filters-metrics.html) plugin

Launch sample with:

```bash
bin/logstash -f samples/metrics.conf
```

Mocked events will be sent to Sumo Logic server as 1 minute and 15 minutes rate metrics.

### 6. Get result from Sumo Logic web app

Logon to Sumo Logic [web app](https://service.sumologic.com/) and run

- [Log Search](http://help.sumologic.com/Search)
- [Live Tail](http://help.sumologic.com/Search/Live_Tail)
- [Metrics Search](https://help.sumologic.com/Metrics)

## What's Next

- Try it with different input/filter/codec plugins
- Start LogStash as a service/daemon in your production environment
- Report any issue or idea through [Git Hub](https://github.com/SumoLogic/logstash-output-sumologic)

## Parameters of Plugin

| Parameter              | Type    | Required? | Default value | Description           |
| ---------------------- | ------- | --------- | :-----------: | --------------------- |
| `url`                  | string  | Yes       |               | HTTP Source URL
| `source_category`      | string  | No        | `Logstash`    | Source category to appear when searching in Sumo Logic by `_sourceCategory`. Using empty string if want keep source category of the HTTP source.
| `source_name`          | string  | No        | `logstash-output-sumologic` | Source name to appear when searching in Sumo Logic by `_sourceName`. Using empty string if want keep source name of the HTTP source.
| `source_host`          | string  | No        | machine name  | Source host to appear when searching in Sumo Logic by `_sourceHost`. Using empty string if want keep source host of the HTTP source.
| `extra_headers`        | hash    | No        |               | Extra fields need to be send in HTTP headers.
| `compress`             | boolean | No        | `false`       | Enable or disable compression.
| `compress_encoding`    | string  | No        | `"deflate"`   | Encoding method of comressing, can only be `"deflate"` or `"gzip"`.
| `interval`             | number  | No        | `0`           | The maximum time for waiting before sending the message pile, in seconds.
| `pile_max`             | number  | No        | `102400`      | The maximum size of message pile, in bytes.
| `queue_max`            | number  | No        | `4096`        | The maximum message piles can be hold in memory.
| `sender_max`           | number  | No        | `100`         | The maximum HTTP senders working in parallel.
| `format`               | string  | No        | `"%{@timestamp} %{host} %{message}"` | For log only, the formatter of log lines. Use `%{@json}` as the placeholder for whole event json.
| `json_mapping`         | hash    | No        |               | Override the structure of `{@json}` tag with the given key value pairs.<br />For example:<br />`json_mapping => { "foo" => "%{@timestamp}" "bar" => "%{message}" }`<br />will create messages as:<br />`{"foo":"2016-07-27T18:37:59.460Z","bar":"hello world"}`<br />`{"foo":"2016-07-27T18:38:01.222Z","bar":"bye!"}`
| `metrics`              | hash    | No        |               | If defined, the event will be sent as metrics. Keys will be the metrics name and values will be the metrics value.
| `metrics_format`       | string  | No        | `"cabon2"`    | Metrics format, can only be `"graphite"` or `"carbon2"`.
| `metrics_name`         | string  | No        | `"*"`         | Define the metric name looking, the placeholder "*" will be replaced with the actual metric name.
| `intrinsic_tags`       | hash    | No        |               | For carbon2 format only, send extra intrinsic key-value pairs other than `metric` (which is the metric name).
| `meta_tags`            | hash    | No        |               | For carbon2 format only, send metadata key-value pairs.
| `fields_as_metrics`    | boolean | No        | `false`       | If `true`, all fields in logstash event with number value will be sent as a metrics (with filtering by `fields_include` and `fields_exclude` ; the `metics` parameter is ignored.
| `fields_include`       | array   | No        | all fields    | Working with `fields_as_metrics` parameter, only the fields which full name matching these RegEx pattern(s) will be included in metrics.
| `fields_exclude`       | array   | No        | none          | Working with `fields_as_metrics` parameter, the fields which full name matching these RegEx pattern(s) will be ignored in metrics.
| `sleep_before_requeue` | number  | No        | `30`          | The message failed to send to server will be retried after (x) seconds. Not retried if negative number set
| `stats_enabled`        | boolean | No        | `false`       | If `true`, stats of this plugin will be sent as metrics
| `stats_interval`       | number  | No        | `60`          | The stats will be sent every (x) seconds

This plugin is based on [logstash-mixin-http_client](https://github.com/logstash-plugins/logstash-mixin-http_client) thus also supports all HTTP layer parameters like proxy, authentication, timeout etc.

## Trouble Shooting

### Enable plugin logging

Logstash is using log4j2 framework for [logging](https://www.elastic.co/guide/en/logstash/current/logging.html). Starting with 5.0, each individual plugin can configure the logging strategy. [Here](https://github.com/SumoLogic/logstash-output-sumologic/blob/master/samples/log4j2.properties) is a sample log4j2.properties to print plugin log to console and a rotating file.

### Optimize throughput

The throughput can be tuning with following parameters:

- Messages will be piled before sending if both `interval` and `pile_max` are larger than `0`. (e.g. multiple messages will sent in single HTTP request); The maximum size of pile is defined in `pile_max` and if there is no more message comes in, piled message will be sent out every `interval` seconds. A higher number of these parameters normally means more messages will be piled together so overall reduce the overhead in transmission and benefit for compressing efficiency; but it may make a larger latency because messages may be hold in plugin for longer before sending;
- Message piles will be cached before sending in a memory queue. The maximum piles can stay in queue is defined with `queue_max`. A larger setting may be helpful if input is blocked by the plugin consuming speed, but may also consume more RAM (which can be set in [JVM options](https://www.elastic.co/guide/en/logstash/current/config-setting-files.html))
- The plugin will use up to `sender_max` HTTP senders in parallel for talking to Sumo Logic server. This number is also limited by the max TCP connections
- Depends on the content pattern, adjusting `compress`/`compress_encoding` for balancing between the CPU consumption and package size

On the other side, this version is marked as thread safe so if necessary, multiple plugins can work [in parallel as workers](https://www.elastic.co/guide/en/logstash/current/tuning-logstash.html)

### Monitor throughput in metrics

If your Sumo Logic account supports metrics feature, you can enable the stats monitor of this plugin with configuring `stats_enabled` to `true`. For every `stats_interval` seconds, a batch of metrics data points will be sent to Sumo Logic with source category `XXX.stats` (`XXX` is the source category of main output):

| Metric                          | Description                                                 |
| ------------------------------- | ----------------------------------------------------------- |
| `total_input_events`            | Total number of events handled from the plugin startup
| `total_input_bytes`             | Total bytes of inputs after encoded to payload
| `total_metrics_datapoints`      | Total metrics data points generated from input
| `total_log_lines`               | Total log lines generated from input
| `total_output_requests`         | Total number of HTTP requests sent to Sumo Logic server
| `total_output_bytes`            | Total bytes of payloads sent to Sumo Logic server
| `total_output_bytes_compressed` | Total bytes of payloads sent to Sumo Logic server (after compressing)
| `total_response_times`          | Total number of responses acknowledged by Sumo Logic server
| `total_response_success`        | Total number of accepted(200) acknowledged by Sumo Logic server

**NOTE:** The data points will consume DPM quota


### TLS 1.2 Requirement

Sumo Logic only accepts connections from clients using TLS version 1.2 or greater. To utilize the content of this repo, ensure that it's running in an execution environment that is configured to use TLS 1.2 or greater.
