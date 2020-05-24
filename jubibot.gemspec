Gem::Specification.new do |spec|
  spec.name          = "jubibot"
  spec.version       = "1.0"
  spec.date          = "2020-05-23"
  spec.summary       = %q{Discord Command Bot.}
  spec.authors       = ["Justin Bishop"]
  spec.email         = ["jubishop@gmail.com"]
  spec.homepage      = "https://github.com/jubishop/jubibot"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.1")
  spec.metadata["source_code_uri"] = "https://github.com/jubishop/jubibot"
  spec.files         = Dir["lib/**/*.rb"]
  spec.add_runtime_dependency 'core'
  spec.add_runtime_dependency 'csv'
  spec.add_runtime_dependency 'discordrb'
  spec.add_runtime_dependency 'rstruct'
end
