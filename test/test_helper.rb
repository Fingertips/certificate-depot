begin
  require 'rubygems'
rescue LoadError
end

require 'mocha'
require 'test/spec'

$:.unshift(File.expand_path('../../lib', __FILE__))
require 'certificate_depot'

$:.unshift(File.expand_path('../test_helper', __FILE__))
require 'temporary_directory'
require 'capture_output'


module Test::Spec::TestCase::InstanceMethods
  include TestHelper::TemporaryDirectory
  include TestHelper::CaptureOutput
end