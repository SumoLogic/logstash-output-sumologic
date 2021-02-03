# Developer Container

Logstash has many dependencies/versions,
and the developing/building behavior is not consistent on different platforms (like on Mac or Linux).
This container is provided as a cross-platform development environment in Docker container.
It pre-installs jruby, logstash, git and clones the latest main branch of plugin locally.
With this environment, you can build, test and run your local version of plugin with ease.

## Build Docker Image

On the machine with latest docker installed:

```bash
docker build -f ./Dockerfile -t sumologic/logstash-dev-container .
```

## Run Docker Container

This command can create a docker container with fully prepared environment and attach the console into it.

```bash
docker run -it sumologic/logstash-dev-container
```

Alternatively, you can also run it in the detach mode with:

```bash
docker run -d sumologic/logstash-dev-container keep-alive -v ~/git/logstash-output-sumologic/:/root
```

The container will keep alive. And later on, you can use:

```bash
docker exec -it <container ID> /bin/bash
```

for reconnect to the environment.

## Build and install the private version of plugin (in container)

```bash
gem build ./logstash-output-sumologic.gemspec
```

## Install and run the private version of plugin (in container)

```bash
logstash-plugin install ./logstash-output-sumologic-<version>.gem
logstash -f ./samples/log.conf
```

## Run unit test (in container)

```bash
rspec ./spec/
```
