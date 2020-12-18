FROM docker.elastic.co/logstash/logstash-oss:7.9.3
USER root

COPY logstash-output-sumologic-*.gem ./
RUN logstash-plugin install logstash-output-sumologic-*.gem

COPY log4j2.properties ./config/
COPY logstash.conf logstash.conf.tmpl
COPY run.sh ./
COPY logs.txt ./

ENTRYPOINT ["/bin/bash", "run.sh"]
