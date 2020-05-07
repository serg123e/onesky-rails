task install: :build do
  sh("gem install onesky-rails-1.4.1.zem.gem")
end

task build: :spec do
  sh("gem build onesky-rails.gemspec")
end

begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec) { |t| t.verbose = false }

  task :default => :spec
rescue LoadError
  p "no rspec available"
end
