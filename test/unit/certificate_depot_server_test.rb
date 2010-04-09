require File.expand_path('../../test_helper', __FILE__)

describe "CertificateDepot::Server" do
  before do
    @depot = mock('Depot')
  end
  
  xit "accepts options which override defaults" do
    expected = CertificateDepot::Server::DEFAULTS.dup
    expected[:port] = 234
    
    @server = CertificateDepot::Server.new(@depot, {
      :port => 234
    })
    @server.instance_eval { @options}.should == expected
  end
end