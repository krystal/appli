Gem::Specification.new do |s|
  s.name = 'appli'
  s.version = "2.0.3"
  s.platform = Gem::Platform::RUBY
  s.summary = "Deployment Recipes for Appli"
  s.files = ["bin/applify", "lib/appli/deploy.rb", "doc/Capfile"]
  s.bindir = "bin"
  s.executables << "applify"
  s.require_path = 'lib'
  s.has_rdoc = false
  s.author = "Adam Cooke"
  s.email = "adam@atechmedia.com"
  s.homepage = "http://www.applihq.com"
end

