# Change Log

## 1.4.0 (2021-09-27)

- [#68](https://github.com/SumoLogic/logstash-output-sumologic/pull/68) feat: retry on 502 error code

## 1.3.2 (2021-02-03)

- [#60](https://github.com/SumoLogic/logstash-output-sumologic/pull/60) Fix plugin metrics not being sent

## 1.3.1 (2020-12-18)

- [#53](https://github.com/SumoLogic/logstash-output-sumologic/pull/53) Fix "undefined method `blank?'"
- [#52](https://github.com/SumoLogic/logstash-output-sumologic/pull/52) Fix logstash-plugin-http_client version conflict in Logstash 7

## 1.3.0

- [#41](https://github.com/SumoLogic/logstash-output-sumologic/pull/41) Provide Docker image with Logstash 6.6 + output plugin on docker hub
- [#41](https://github.com/SumoLogic/logstash-output-sumologic/pull/41) Kubernetes support with Logstash beats to SumoLogic
- [#41](https://github.com/SumoLogic/logstash-output-sumologic/pull/41) CI improving 
- [#36](https://github.com/SumoLogic/logstash-output-sumologic/pull/36) Update sender to send in batch.
- [#36](https://github.com/SumoLogic/logstash-output-sumologic/pull/36) Support %{} field evaluation in `source_category`, `source_name`, `source_host` parameters
- [#39](https://github.com/SumoLogic/logstash-output-sumologic/pull/39) Disable cookies by default

## 1.2.2

- Bug fix: memory leak when using `%{@json}` in format

## 1.2.1

- Bug fix on plug-in logging and samples

## 1.2.0

- Support message piling with both `interval` and `pile_max`
- Support in memory message queue to overall enhance throughput
- Retry sending when get throttled or temporary server problem
- Support monitor throughput statistics in metrics

## 1.1.0

- Support metrics sending

## 1.0.0

- Initial release
