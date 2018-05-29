# Sample - Integrate DockBeat to SumoLogic

## Build

```bash
docker build -f ./Dockerfile -t sumologic/dockbeat-integration .
```

## Run

```bash
docker run -d -v /var/run/docker.sock:/var/run/docker.sock sumologic/dockbeat-integration <HTTP Source URL> [Source Name] [Source Category]
```

## Customizable

You can pass following environment variables when `docker run`

| Variable               | Description
| :--------------------- | ------------ |
|`SUMO_LOGSTASH_CONF`    | The configure file used by logstash. You can mount another configure file and use it by setting this variable
|`SUMO_HTTP_URL`         | URL of HTTP source
|`SUMO_SOURCE_NAME`      | `_sourceName` when searching on Sumo
|`SUMO_SOURCE_CATEGORY`  | `_sourceCategory` when searching on Sumo
