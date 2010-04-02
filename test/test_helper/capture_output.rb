module TestHelper
  module CaptureOutput
    class Collector
      attr_reader :written
      def initialize
        @written = []
      end
      
      def write(string)
        @written << string
      end
    end
    
    def capture_stdout(&block)
      collector = Collector.new
      stdout = $stdout
      $stdout = collector
      begin
        block.call
      ensure
        $stdout = stdout
      end
      collector.written.join
    end
  end
end