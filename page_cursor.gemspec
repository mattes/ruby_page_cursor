$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "page_cursor/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "page_cursor"
  spec.version     = PageCursor::VERSION
  spec.authors     = ["Matthias Kadenbach"]
  spec.email       = ["matthias.kadenbach@gmail.com"]
  spec.homepage    = "https://github.com/mattes/ruby_page_cursor"
  spec.summary     = "Cursor-based pagination"
  spec.description = "Cursor-based pagination for Rails."
  spec.license     = "MIT"

  spec.files = Dir["{app,config,db,lib}/**/*", "LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", "~> 6"

  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "ksuid"
end
