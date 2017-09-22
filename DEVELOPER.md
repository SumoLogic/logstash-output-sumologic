# logstash-output-sumologic
Logstash output plugin for delivering log to Sumo Logic cloud service through HTTP source.

# How to build .gem file from repository
Open logstash-output-sumologic.gemspec and make any necessary configuration changes.
In your local Git clone, run:
```sh
gem build logstash-output-sumologic.gemspec
```
You will get a .gem file in the same directory as `logstash-output-sumologic-x.y.z.gem`
Remove old version of plugin (optional):
```sh
bin/logstash-plugin remove logstash-output-sumologic
```
And then install the plugin locally:
```sh
bin/logstash-plugin install <full path of .gem>
```

# How to run test with rspec
The test requires JRuby to run. So you need to install [JRuby](http://jruby.org/) and [RVM](https://rvm.io/) (for switching between JRuby and Ruby) first.
And then run:
```bash
rvm use jruby
rspec spec/
```

