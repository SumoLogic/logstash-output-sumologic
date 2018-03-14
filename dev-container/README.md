# Developer Container
Logstash has many dependencies/versions, and the developing/building behavior is not consistent on different platforms (like on Mac or Linux). This container is provided as a cross-platform developer environment in Docker container (It pre-install jruby/logstash/github and clone the latest master branch of plugin locally). With this environment, you can build/test your private version of plugin easier.

# Build Docker Image
On the machine with latest docker installed:
```
$ docker build -f ./Dockerfile -t sumologic/logstash-dev-container .
```

# Run Docker Container
```
docker run -it sumologic/logstash-dev-container
```

# Build and install the private version of plugin (in container)
```
gem build ./logstash-output-sumologic.gemspec
```

# Install and run the private version of plugin (in container)
```
logstash-plugin install ./logstash-output-sumologic-<version>.gem
logstash -f ./samples/log.conf
```

# Run unit test (in container)
```
rspec ./spec/
```