class CertificateDepot
  class Keypair
    DEFAULT_LENGTH = 2048
    
    attr_accessor :private_key
    
    def initialize(private_key=nil)
      @private_key = private_key
    end
    
    def generate
      @private_key = OpenSSL::PKey::RSA.generate(DEFAULT_LENGTH)
    end
    
    def public_key
      @private_key.public_key
    end
    
    def self.generate
      keypair = new
      keypair.generate
      keypair
    end
  end
end