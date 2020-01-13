#!/bin/sh

echo "Starting build process in: `pwd`"
set -e

VERSION_IN_GEMSPEC=`cat logstash-output-sumologic.gemspec | grep "s.version" | cut -d= -f2 | tr -d '[:space:]'`
VERSION="${TRAVIS_TAG:-0.0.0}"
VERSION="${VERSION#v}"
: "${DOCKER_TAG:=sumologic/logstash-output-sumologic}"
: "${DOCKER_USERNAME:=sumodocker}"
PLUGIN_NAME="logstash-output-sumologic"

echo "Building for tag $VERSION, modify .gemspec file..."
sed -i.bak "s/$VERSION_IN_GEMSPEC/$VERSION/g" ./$PLUGIN_NAME.gemspec
rm -f ./$PLUGIN_NAME.gemspec.bak

exit 1

echo "Install bundler..."
bundle install

echo "Build gem $PLUGIN_NAME $VERSION..."
gem build $PLUGIN_NAME
mv -f ./$PLUGIN_NAME-$VERSION.gem ./deploy/docker/$PLUGIN_NAME.gem

echo "Building docker image with $DOCKER_TAG:$VERSION and $DOCKER_TAG:latest in `pwd`..."
docker build ./deploy/docker -f ./deploy/docker/Dockerfile -t $DOCKER_TAG:v$VERSION --no-cache
docker build ./deploy/docker -f ./deploy/docker/Dockerfile -t $DOCKER_TAG:latest
if [ -z "$DOCKER_PASSWORD" ] || [ -z "$TRAVIS_TAG" ]; then
    echo "Skip Docker pushing"
else
    echo "Pushing docker image with $DOCKER_TAG:$VERSION and $DOCKER_TAG:latest..."
    echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
    docker push $DOCKER_TAG:v$VERSION
    docker push $DOCKER_TAG:latest
fi

rm -f ../deploy/docker/$PLUGIN_NAME.gem

echo "DONE"
