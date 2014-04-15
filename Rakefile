# encoding: utf-8

require 'rubygems'
require 'bundler'
require 'semver'

def s_version
  SemVer.find.format "%M.%m.%p%s"
end

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "rubyneat"
  gem.homepage = "http://rubyneat.com"
  gem.license = "MIT"
  gem.summary = %Q{RubyNEAT NeuralEvolution of Augmenting Topologies}
  gem.version = s_version
  gem.description = %Q{
  RubyNEAT -- Neural Evolution of Augmenting Topologies for Ruby.
  By way of an enhanced form of Genetic Algorithms -- the NEAT algorithm,
  populations of neural nets are evolved to handle pre-defined goals.

  RubyNEAT is the first implementation of the NEAT algorithm for Ruby, and
  it leverages Ruby's power to implement the NEAT algorithm in a way that would
  be difficult to do in other languages. The 'activation function' is largely
  standalone. Basically, activation is achieved by functional programming.

  Meaning, once your network is evolved, you can extract it as source code you
  can then utilize without the RubyNEAT engine.

  RubyNEAT can be used for nearly any Machine Learning task you can dream of,
  because it's also extensible and modular. See http://rubyneat.com for the
  details.
  }
  gem.email = "fred@lrcsoft.com"
  gem.authors = ["Fred Mitchell"]
  # dependencies defined in Gemfile

  # Exclude the Neural Docs directory
  gem.files.exclude 'Neural_Docs/*', 'foo/**/*', 'rdoc/*',
                    '.idea/**/*', '.idea/**/.*', '.yardoc/**/*',
                    'public/**/*', 'neater/**/*', 'doc/**/*',
                    'public/**/.*', 'Guardfile'
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = s_version

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "rubyneat #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('rnlib/**/*.rb')
end
