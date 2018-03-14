# Developer Container
Logstash has many dependencies/versions, and the developing/building behavior is not consistent on different platforms (like on Mac or Linux). This container is provided as a cross-platform developer environment in Docker container (It pre-install jruby/logstash/github and clone the latest master branch of plugin locally). With this environment, you can build/test your private version of plugin easier.

## Build Docker Image
On the machine with latest docker installed:
```
$ docker build -f ./Dockerfile -t sumologic/logstash-dev-container .
```

## Run Docker Container
This command can create a docker container with fully prepared environment and attach the console into it.
```
docker run -it sumologic/logstash-dev-container
```
Alternatively, you can also run it in the detach mode with:
```
docker run -d sumologic/logstash-dev-container keep-alive
```
The container will keep alive. And later on, you can use:
```
docker exec -it <container ID> /bin/bash
```
for reconnect to the environment.

## Build and install the private version of plugin (in container)
```
gem build ./logstash-output-sumologic.gemspec
```

## Install and run the private version of plugin (in container)
```
logstash-plugin install ./logstash-output-sumologic-<version>.gem
logstash -f ./samples/log.conf
```

## Run unit test (in container)
```
rspec ./spec/
```