class CertificateDepot
  class Certificate
    DEFAULT_VALIDITY_PERIOD = 3600 * 24 * 365 * 10
    X509v3 = 2
    
    ATTRIBUTE_MAP = {
      :organization  => 'O',
      :email_address => 'emailAddress',
      :common_name   => 'CN'
    }
    
    attr_accessor :certificate
    
    def initialize(certificate=nil)
      @certificate = certificate
    end
    
    def generate(attributes={})
      from         = Time.now
      to           = Time.now + DEFAULT_VALIDITY_PERIOD
      
      name         =  OpenSSL::X509::Name.new
      ATTRIBUTE_MAP.each do |internal, x509_attribute|
        name.add_entry(x509_attribute, attributes[internal]) if attributes[internal]
      end
      
      if attributes[:ca_certificate]
        issuer = attributes[:ca_certificate].subject
        serial = attributes[:serial_number]
      else
        issuer = name
        serial = 0
      end
      
      raise ArgumentError, "Please supply a serial number for the certificate to generate" unless serial
      
      @certificate = OpenSSL::X509::Certificate.new
      @certificate.subject    = name
      @certificate.issuer     = issuer
      @certificate.not_before = from
      @certificate.not_after  = to
      @certificate.version    = X509v3
      @certificate.public_key = attributes[:public_key]
      @certificate.serial     = serial
      
      extensions = []
      factory = OpenSSL::X509::ExtensionFactory.new
      factory.subject_certificate = @certificate
      
      if attributes[:ca_certificate] # Client certificate
        factory.issuer_certificate = attributes[:ca_certificate].certificate
        extensions << factory.create_extension('basicConstraints', 'CA:FALSE', true)
        extensions << factory.create_extension('keyUsage', 'nonRepudiation,digitalSignature,keyEncipherment')
        extensions << factory.create_extension('extendedKeyUsage', 'clientAuth')
      else # CA certificate
        factory.issuer_certificate = @certificate
        extensions << factory.create_extension('basicConstraints', 'CA:TRUE', true)
        extensions << factory.create_extension('keyUsage', 'cRLSign,keyCertSign')
      end
      extensions << factory.create_extension('subjectKeyIdentifier', 'hash')
      extensions << factory.create_extension('authorityKeyIdentifier', 'keyid,issuer:always')
      
      @certificate.extensions = extensions
      
      if attributes[:private_key]
        @certificate.sign(attributes[:private_key], OpenSSL::Digest::SHA1.new)
      end
      
      @certificate
    end
    
    def write_to(path)
      File.open(path, 'w') { |file| file.write(@certificate.to_pem) }
    end
    
    def public_key
      @certificate.public_key
    end
    
    def issuer
      @certificate.issuer
    end
    
    def subject
      @certificate.subject
    end
    
    def serial_number
      @certificate.serial
    end
    
    def method_missing(method, *attributes, &block)
      if x509_attribute = ATTRIBUTE_MAP[method.to_sym]
        self[x509_attribute]
      else
        super
      end
    end
    
    def [](key)
      @certificate.subject.to_a.each do |name, value, type|
        return value if name == key
      end; nil
    end
    
    def self.generate(public_key)
      certificate = new
      certificate.generate(public_key)
      certificate
    end
    
    def self.from_file(path)
      new(OpenSSL::X509::Certificate.new(File.read(path)))
    end
  end
end