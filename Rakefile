require 'rake/testtask'

desc "Run all tests by default"
task :default => :test

desc "Run all test"
Rake::TestTask.new do |t|
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end
