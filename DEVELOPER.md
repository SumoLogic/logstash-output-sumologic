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

The test requires JRuby to run. So you need to install [JRuby](http://jruby.org/), [bundle](https://bundler.io/bundle_install.html) and [RVM](https://rvm.io/) (for switching between JRuby and Ruby) first.
And then run:

```bash
rvm use jruby
bundle install
export sumo_url=https://events.sumologic.net/receiver/v1/http/XXXXXXXXXX
rspec spec/
```

The project is integrated to the Travis CI now. Make sure [all test passed](https://travis-ci.org/SumoLogic/logstash-output-sumologic) before creating PR