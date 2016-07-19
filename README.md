# Logstash Sumo Logic Output Plugin

This is a plugin for [Logstash](https://github.com/elastic/logstash).
It is fully free and fully open source. The license is Apache 2.0, meaning you are pretty much free to use it however you want in whatever way.

## Getting Started

### 1. Create a Sumo Logic HTTP source
- Create a [Sumo Logic](https://www.sumologic.com/) free account if you currently don't have one.
- Create a [HTTP source](http://help.sumologic.com/Send_Data/Sources/HTTP_Source) in your account and get the URL for this source. It should be something like 
```
https://events.sumologic.net/receiver/v1/http/XXXXXXXXXX
```

### 2. Install LogStash on your machine
- Following this [instruction](https://www.elastic.co/guide/en/logstash/current/getting-started-with-logstash.html) to download and install LogStash. This plugin require Logstash 2.3 or higher to run.

### 3. Build plugin gem and install to LogStash
- Build your plugin gem

In your local Git clone, running:
```sh
gem build logstash-output-sumologic.gemspec
```

You will get a .gem file as `logstash-output-sumologic-1.0.0.gem`

- Install plugin into LogStash

In the Logstash home, running:
```sh
bin/logstash-plugin install <path of .gem>
```

### 4. Start Logstash and send log
In the Logstash home, running:
```sh
bin/logstash -e 'input{stdin{}}output{sumologic{url=>"<url from step 1>"}}'
```

This will send any input from console to Sumo Logic cloud service.

### 5. Get result from Sumo Logic web app
- Logon to Sumo Logic [web app](https://prod-www.sumologic.net/ui/) and run [Search](http://help.sumologic.com/Search) or [Live Tail](http://help.sumologic.com/Search/Live_Tail)

### Further things
- Try it with different input/filter/codec plugins
- Start LogStash as a service/daemon in your production environment 
- Report and issue or idea through [Git Hub](https://github.com/SumoLogic/logstash-output-sumologic)
