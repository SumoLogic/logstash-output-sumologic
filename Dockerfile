FROM jruby:9.2.13.0
WORKDIR /app
COPY Gemfile logstash-output-sumologic.gemspec ./
RUN bundle install
COPY . .
CMD ["rspec"]
