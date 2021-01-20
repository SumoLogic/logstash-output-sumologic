# Development Guide

Logstash output plugin for delivering log to Sumo Logic cloud service through HTTP source.

## How to build .gem file from repository

Open logstash-output-sumologic.gemspec and make any necessary configuration changes.
In your local Git clone, run:

```bash
gem build logstash-output-sumologic.gemspec
```

You will get a .gem file in the same directory as `logstash-output-sumologic-x.y.z.gem`
Remove old version of plugin (optional):

```bash
bin/logstash-plugin remove logstash-output-sumologic
```

And then install the plugin locally:

```bash
bin/logstash-plugin install <full path of .gem>
```

## How to run test with rspec

### Running in Docker

```bash
docker build -t logstash-output-plugin .
docker run --rm -it -e 'sumo_url=https://events.sumologic.net/receiver/v1/http/XXXXXXXXXX' logstash-output-plugin
```

### Running on bare metal

The test requires JRuby to run.

```bash
rvm use jruby
bundle install
export sumo_url=https://events.sumologic.net/receiver/v1/http/XXXXXXXXXX
rspec spec/
```

## Continuous Integration

The project uses GitHub Actions for:

- Testing pull requests and main branch commits: [.github/workflows/ci.yml](.github/workflows/ci.yml)
- Publishing new version of gem to RubyGems.org after tagging: [.github/workflows/publish.yml](.github/workflows/publish.yml)

Before publishing a new version, make sure the RubyGems account has MFA disabled for API access.
Go to [Settings](https://rubygems.org/settings/edit) and set `MFA Level` to `UI only`.
