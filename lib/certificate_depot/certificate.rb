class CertificateDepot
  class Certificate
    DEFAULT_VALIDITY_PERIOD = 3600 * 24 * 365 * 10
    X509v3 = 2
    
    attr_accessor :certificate
    
    def initialize(certificate=nil)
      @certificate = certificate
    end
    
    def generate(public_key)
      from         = Time.now
      to           = Time.now + DEFAULT_VALIDITY_PERIOD
      name         = OpenSSL::X509::Name.parse('/C=NL/O=Fingertips/CN=Manfred Stienstra/emailAddress=manfred@fngtps.com')
      
      @certificate = OpenSSL::X509::Certificate.new
      @certificate.subject    = name
      @certificate.issuer     = name
      @certificate.not_before = from
      @certificate.not_after  = to
      @certificate.version    = X509v3
      @certificate.public_key = public_key
    end
    
    def write_to(path)
      File.open(path, 'w') { |file| file.write(@certificate.to_pem) }
      File.chmod(0400, path)
    end
    
    def public_key
      @certificate.public_key
    end
    
    def issuer
      @certificate.issuer
    end
    
    def self.generate(public_key)
      certificate = new
      certificate.generate(public_key)
      certificate
    end
  end
end