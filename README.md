# Logstash Sumo Logic Output Plugin

[![Build Status](https://travis-ci.org/SumoLogic/logstash-output-sumologic.svg?branch=master)](https://travis-ci.org/SumoLogic/logstash-output-sumologic)

This is an output plugin for [Logstash](https://github.com/elastic/logstash).
It is fully free and fully open source. The license is Apache 2.0, meaning you are pretty much free to use it however you want in whatever way.

| TLS Deprecation Notice |
| --- |
| In keeping with industry standard security best practices, as of May 31, 2018, the Sumo Logic service will only support TLS version 1.2 going forward. Verify that all connections to Sumo Logic endpoints are made from software that supports TLS 1.2. |

| TLS Deprecation Notice |
| --- |
| In keeping with industry standard security best practices, as of May 31, 2018, the Sumo Logic service will only support TLS version 1.2 going forward. Verify that all connections to Sumo Logic endpoints are made from software that supports TLS 1.2. |

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

Open samples/sample-logs.conf, replace #URL# placeholder as real URL got from step 1

Launch sample with:

```bash
bin/logstash -f samples/log.conf
```

The input from console will be sent to Sumo Logic cloud service as log lines.

Open samples/sample-metrics.conf, replace #URL# placeholder as real URL got from step 1
(This sample may require installing the [plugins-filters-metrics](https://www.elastic.co/guide/en/logstash/current/plugins-filters-metrics.html) plugin first)

Launch sample with:

```bash
bin/logstash -f samples/metrics.conf
```

A mocked event will be sent to Sumo Logic cloud service as 1 minute and 15 minutes rate metrics.

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

| Parameter              | Type    | Required? | Default value | Decription            |
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
| `json_mapping`         | hash    | No        |               | Override the structure of `{@json}` tag with the given key value pairs. <br />For example:<br />`json_mapping => { "foo" => "%{@timestamp}" "bar" => "%{message}" }`<br />will create messages as:<br />`{"foo":"2016-07-27T18:37:59.460Z","bar":"hello world"}`<br />`{"foo":"2016-07-27T18:38:01.222Z","bar":"bye!"}`
| `metrics`              | hash    | No        |               | If defined, the event will be sent as metrics. Keys will be the metrics name and values will be the metrics value.
| `metrics_format`       | string  | No        | `"cabon2"`    | Metrics format, can only be `"graphite"` or `"carbon2"`.
| `metrics_name`         | string  | No        | `"*"`         | Define the metric name looking, the placeholder "*" will be replaced with the actual metric name.
| `intrinsic_tags`       | hash    | No        |               | For carbon2 format only, send extra intrinsic key-value pairs other than `metric` (which is the metric name).
| `meta_tags`            | hash    | No        |               | For carbon2 format only, send metadata key-value pairs.
| `fields_as_metrics`    | boolean | No        | `false`       | If `true`, all fields in logstash event with number value will be sent as a metrics (with filtering by `fields_include` and `fields_exclude` ; the `metics` parameter is ignored.
| `fields_include`       | array   | No        | all fields    | Working with `fields_as_metrics` parameter, only the fields which full name matching these RegEx pattern(s) will be included in metrics.
| `fields_exclude`       | array   | No        | none          | Working with `fields_as_metrics` parameter, the fields which full name matching these RegEx pattern(s) will be ignored in metrics.
| `sleep_before_requeue` | number  | No       | `30`           | The message failed to send to server will be retried after (x) seconds. Not retried if negative number set
| `stats_enabled`        | boolean | No       | `false`        | If `true`, stats of this plugin will be sent as metrics
| `stats_interval`       | number  | No       | `60`           | The stats will be sent every (x) seconds

This plugin is based on [logstash-mixin-http_client](https://github.com/logstash-plugins/logstash-mixin-http_client) thus we also support all HTTP layer parameters like proxy, authentication, retry, etc.
