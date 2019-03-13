FROM docker.elastic.co/logstash/logstash-oss:6.6.0

RUN rm -f /usr/share/logstash/pipeline/logstash.conf
ADD pipeline/ /usr/share/logstash/pipeline/
ADD config/ /usr/share/logstash/config/

RUN logstash-plugin install logstash-output-sumologic