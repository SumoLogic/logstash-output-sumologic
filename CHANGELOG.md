# Change Log

## 1.2.3
- #36
  - Update sender to send in batch.
  - Support %{} field evaluation in `source_category`, `source_name`, `source_host` parameters
- #39 Disable cookies by default
- #41
  - Provide Docker image with Logstash 6.6 + output plugin on docker hub
  - Kubernetes support with Logstash beats to SumoLogic
  - CI improving

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
