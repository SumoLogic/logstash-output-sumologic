FROM jruby:9.1.13.0
WORKDIR /app
COPY Gemfile logstash-output-sumologic.gemspec ./
RUN bundle install
COPY . .
CMD ["rspec"]
