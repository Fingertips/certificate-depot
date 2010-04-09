begin
  require 'rubygems'
rescue LoadError
end

require 'test/spec'
require 'mocha'

$:.unshift(File.expand_path('../../lib', __FILE__))
require 'certificate_depot'

$:.unshift(File.expand_path('../test_helper', __FILE__))
require 'collector'
require 'capture_output'
require 'temporary_directory'

module Test::Spec::TestCase::InstanceMethods
  include TestHelper::TemporaryDirectory
  include TestHelper::CaptureOutput
end