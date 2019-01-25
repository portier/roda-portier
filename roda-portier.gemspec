# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'roda/plugins/portier/version'

Gem::Specification.new do |spec|
	spec.name          = "roda-portier"
	spec.version       = Roda::RodaPlugins::Portier::VERSION
	spec.authors       = ["Malte Paskuda"]
	spec.email         = ["malte@paskuda.biz"]

	spec.summary       = %q{Adds portier authentication to Roda}
	spec.description   = %q{Adds portier authentication to Roda}
	spec.homepage      = "https://github.com/portier/roda-portier"
	spec.license       = "MIT"

	spec.add_dependency "roda", ">= 2.0"
	spec.add_dependency "jwt", ">= 1.5.4"
	spec.add_dependency "url_safe_base64", ">= 0.2.2"
	spec.add_dependency "simpleidn", ">= 0.0.9"
end
