# Sumo Logic log stash output plugin sample

FROM logstash:latest

USER root
COPY dockbeat /usr/local/bin/
RUN ["chmod", "+x", "/usr/local/bin/dockbeat"]
COPY dockbeat.yml dockbeat.yml
COPY LICENSE-DOCKBEAT LICENSE-DOCKBEAT

COPY logstash-output-sumologic-1.1.9.gem logstash-output-sumologic-1.1.9.gem
RUN logstash-plugin install logstash-output-sumologic-1.1.9.gem

COPY logstash-filter-metrics-4.0.4.gem logstash-filter-metrics-4.0.4.gem
RUN logstash-plugin install logstash-filter-metrics-4.0.4.gem

COPY logstash.conf logstash.conf.tmpl
COPY run.sh run.sh 
RUN ["chmod", "+x", "run.sh"]

ENTRYPOINT ["/bin/bash", "run.sh"]
