# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "lfconvert/version"

Gem::Specification.new do |spec|
  spec.name          = 'lfconvert'
  spec.version       = LFConvert::VERSION
  spec.authors       = ['Orest Kulik']
  spec.email         = 'orest@nisdom.com'

  spec.summary       = 'USD to EUR converter'
  spec.description   = "Converts USD amount to EUR on the given date from ECB exchange rates"
  spec.platform      = Gem::Platform::RUBY
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.0.0'

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
