# Example: Send logs from file to Sumo Logic

This example sends logs from `logs.txt` file into your Sumo HTTP source.

## Prerequisites

Download the latest plugin's release into current directory.

```bash
curl -s https://api.github.com/repos/SumoLogic/logstash-output-sumologic/releases/latest |
  grep browser_download_url |
  cut -d '"' -f 4 |
  xargs curl --remote-name --silent
```

The above command should download a file `logstash-output-sumologic-<version>.gem` into current directory.

## Build

```bash
docker build -t logstash-output-sumologic-file-input-example .
```

## Run

```bash
docker run --rm -it logstash-output-sumologic-file-input-example <HTTP Source URL> [Source Name] [Source Category]
```

## Customize

You can pass following environment variables to `docker run`.

| Variable               | Description
| :--------------------- | ------------ |
|`SUMO_LOGSTASH_CONF`    | The configure file used by logstash. You can mount another configure file and use it by setting this variable
|`SUMO_HTTP_URL`         | URL of HTTP source
|`SUMO_SOURCE_NAME`      | `_sourceName` when searching on Sumo
|`SUMO_SOURCE_CATEGORY`  | `_sourceCategory` when searching on Sumo
