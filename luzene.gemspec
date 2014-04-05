$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "luzene/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "luzene"
  s.version     = Luzene::VERSION
  s.authors     = ["Peter Cepeda"]
  s.email       = ["cepeda617@gmail.com"]
  s.homepage    = "http://petercepedadesign.com"
  s.summary     = "Lucene query lexical analyzer and parser"
  s.description = "Lucene query lexical analyzer and parser"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.0.4"
end
