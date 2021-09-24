# Contributing

## Set up development environment

You can use the preconfigured Vagrant virtual machine for development
It includes everything that is needed to start coding.
See [./vagrant/README.md](./vagrant/README.md).

If you don't want to or cannot use Vagrant, you need to install the following dependencies:

- [Java SE](http://www.oracle.com/technetwork/java/javase/downloads/index.html) as a prerequisite to JRuby,
- [JRuby](https://www.jruby.org/),
- [Bundler](https://bundler.io/),
- optionally [Docker](https://docs.docker.com/get-docker/), if you want to build and run container images.

When your machine is ready (either in Vagrant or not), run this in the root directory of this repository:

```sh
bundle install
```

## Running tests

Some of the tests try to send actual data to an actual Sumo Logic account.
To run those tests, you need to make `sumo_url` environment variable available.
If the `sumo_url` environment variable is not present, the tests reaching Sumo Logic will be skipped.

```sh
export sumo_url=https://events.sumologic.net/receiver/v1/http/XXXXXXXXXX
```

To run the tests, execute:

```sh
bundle exec rspec
```

To run tests in Docker, execute:

```sh
docker build -t logstash-output-plugin .
docker run --rm -it -e 'sumo_url=https://events.sumologic.net/receiver/v1/http/XXXXXXXXXX' logstash-output-plugin
```

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

## Continuous Integration

The project uses GitHub Actions for:

- Testing pull requests and main branch commits: [.github/workflows/ci.yml](.github/workflows/ci.yml)
- Publishing new version of gem to RubyGems.org after tagging: [.github/workflows/publish.yml](.github/workflows/publish.yml)

Before publishing a new version, make sure the RubyGems account has MFA disabled for API access.
Go to [Settings](https://rubygems.org/settings/edit) and set `MFA Level` to `UI only`.
