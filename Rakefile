require 'rubygems'
require 'rake/testtask'
require 'rake/rdoctask'

desc "Run all tests by default"
task :default => :test

desc "Run all test"
Rake::TestTask.new do |t|
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end

namespace :documentation do
  Rake::RDocTask.new(:generate) do |rd|
    rd.main = "README.rdoc"
    rd.rdoc_files.include("README.rdoc", "lib/**/*.rb")
    rd.options << "--all" << "--charset" << "utf-8"
  end
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "certificate-depot"
    s.summary = s.description = "Certificate depot is a mini Certification Authority for TLS client certificates."
    s.email = "manfred@fngtps.com"
    s.authors = ["Manfred Stienstra"]
    s.files = FileList['lib/**/*.rb', 'bin/*'].to_a
    s.executables = ['depot']
    s.add_development_dependency('mocha')
    s.add_development_dependency('test-spec')
  end
rescue LoadError
end
