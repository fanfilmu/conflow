# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "conflow/version"

Gem::Specification.new do |spec|
  spec.name          = "conflow"
  spec.version       = Conflow::VERSION
  spec.authors       = ["Michał Begejowicz"]
  spec.email         = ["michal.begejowicz@codesthq.com"]

  spec.required_ruby_version = "~> 2.3"

  spec.summary       = "Redis-backed handling of complicated flows"
  spec.description   = "Redis-backed handling of complicated flows"
  spec.homepage      = "https://github.com/fanfilmu/conflow"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^spec/}) }
  spec.require_paths = ["lib"]

  spec.add_dependency "redis", "~> 4.0"

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "connection_pool", "~> 2.2"
  spec.add_development_dependency "pry", "~> 0.11"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 0.51"
  spec.add_development_dependency "simplecov", "~> 0.15"
end
