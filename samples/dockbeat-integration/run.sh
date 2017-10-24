#!/bin/bash

SUMO_LOGSTASH_CONF=${SUMO_LOGSTASH_CONF:=logstash.conf}
SUMO_HTTP_URL=${SUMO_HTTP_URL:=$1}
SUMO_SOURCE_NAME=${SUMO_SOURCE_NAME:=$2}
SUMO_SOURCE_CATEGORY=${SUMO_SOURCE_CATEGORY:=$3}
SUMO_LOGSTASH_CONF_TMPL=${SUMO_LOGSTASH_CONF}.tmpl

if [ -z "$SUMO_HTTP_URL" ]; then
  echo "FATAL: Please provide a valid HTTP source URL from Sumo."
  exit 1
fi

if [ ! -e "${SUMO_LOGSTASH_CONF_TMPL}" ]; then
  echo "FATAL: Unable to find $SUMO_LOGSTASH_CONF_TMPL - please make sure you include it in your image!"
  exit 1
fi

if [ -z "$SUMO_SOURCE_NAME" ]; then
  SUMO_SOURCE_NAME="dockbeat"
fi

if [ -z "$SUMO_SOURCE_CATEGORY" ]; then
  SUMO_SOURCE_CATEGORY="logstash"
fi

echo > ${SUMO_LOGSTASH_CONF}
if [ $? -ne 0 ]; then
    echo "FATAL: unable to write to ${SUMO_LOGSTASH_CONF}"
    exit 1
fi

OLD_IFS=$IFS
IFS=$'\n'
while read line; do
  line_escape_backslashes=${line//\\/\\\\\\\\}
  echo $(eval echo "\"${line_escape_backslashes//\"/\\\"}\"") >> ${SUMO_LOGSTASH_CONF}
done < ${SUMO_LOGSTASH_CONF_TMPL}
IFS=${OLD_IFS}

dockbeat -c dockbeat.yml -e -v &
logstash -f ${SUMO_LOGSTASH_CONF}
