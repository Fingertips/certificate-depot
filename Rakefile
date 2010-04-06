require 'rake/testtask'

desc "Run all tests by default"
task :default => :test

desc "Run all test"
Rake::TestTask.new do |t|
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "certificate-depot"
    s.summary = s.description = "Certificate depot is a mini Certification Authority for TLS client certificates."
    s.email = "manfred@fngtps.com"
    s.authors = ["Manfred Stienstra"]
    s.files = FileList['lib/**/*.rb', 'bin/*'].to_a
    s.add_development_dependency('mocha')
    s.add_development_dependency('test-spec')
  end
rescue LoadError
end