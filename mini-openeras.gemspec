# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mini-openeras/version'

Gem::Specification.new do |spec|
  spec.name          = "mini-openeras"
  spec.version       = MiniOpeneras::VERSION
  spec.authors       = ["quaqua"]
  spec.email         = ["quaqua@tastenwerk.com"]
  spec.description   = %q{iox extension for the openeras event archiving system}
  spec.summary       = %q{This module extends the iox content management framework with an event management tool for event organisations like theatres}
  spec.homepage      = ""
  spec.license       = "GPLv3"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

end
