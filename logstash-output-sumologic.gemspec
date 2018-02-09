Gem::Specification.new do |s|
  s.name          = "logstash-output-sumologic"
  s.version       = "1.1.1"
  s.licenses      = ["Apache-2.0"]
  s.summary       = "Deliever the log to Sumo Logic cloud service."
  s.description   = "This gem is a Logstash output plugin to deliver the log or metrics to Sumo Logic cloud service. Go to https://github.com/SumoLogic/logstash-output-sumologic for getting help, reporting issues, etc."
  s.authors       = ["Sumo Logic"]
  s.email         = "collection@sumologic.com "
  s.homepage      = "https://github.com/SumoLogic/logstash-output-sumologic"
  s.require_paths = ["lib"]

  # Files
  s.files = Dir["lib/**/*","spec/**/*","vendor/**/*","*.gemspec","*.md","CONTRIBUTORS","Gemfile","LICENSE","NOTICE.TXT"]
   # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "output" }

  # Gem dependencies
  s.add_runtime_dependency "logstash-core-plugin-api", "~> 2.0"
  s.add_runtime_dependency "logstash-codec-plain", ">= 0"
  s.add_development_dependency "logstash-devutils", "~> 0"
end
