require File.expand_path('../../test_helper', __FILE__)

describe "CertificateDepot, concerning the commandline utility" do
  it "creates and invokes the runner when being asked to run" do
    runner = nil
    capture_stdout do
      runner = CertificateDepot.run([])
    end.should == runner.parser.to_s
  end
end