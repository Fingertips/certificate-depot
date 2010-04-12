require File.expand_path('../../test_helper', __FILE__)

describe "CertificateDepot::Log" do
  before do
    @collector = Collector.new
    @collector.stubs(:flock)
    @log = CertificateDepot::Log.new(@collector)
  end
  
  it "logs" do
    @log.log(CertificateDepot::Log::DEBUG, "A message")
    parts = @collector.written.join.split('|')
    parts[0][0,7].should == "[#{Process.pid.to_s.rjust(5)}]"
    parts[1].should == " A message\n"
  end
  
  it "does not log under its loglevel" do
    @log.level = CertificateDepot::Log::WARN
    @log.debug("Info")
    @collector.written.should == []
  end
  
  it "logs above its loglevel" do
    @log.level = CertificateDepot::Log::WARN
    @log.fatal("Info")
    @collector.written.should.not.be.empty
  end
end