class CertificateDepot
  # Represents an OpenSSL RSA key. Because RSA is part of a PKI the private
  # key is usually paired with the public key.
  class Keypair
    DEFAULT_LENGTH = 2048
    
    attr_accessor :private_key
    
    # Instantiate a new Keypair with a private key. The private key should be
    # an instance of OpenSSL::PKey::RSA.
    def initialize(private_key=nil)
      @private_key = private_key
    end
    
    # Generates a new private and public keypair.
    def generate
      @private_key = OpenSSL::PKey::RSA.generate(DEFAULT_LENGTH)
    end
    
    # Returns the public key
    def public_key
      @private_key.public_key
    end
    
    # Writes the keypair to file. The path should be a filename pointing to
    # an existing directory. Note that this will overwrite files without
    # asking.
    def write_to(path)
      File.open(path, 'w') { |file| file.write(@private_key.to_pem) }
      File.chmod(0400, path)
    end
    
    # Shortcut method to generate a new keypair.
    #
    #   keypair = CertificateDepot::Keypair.generate
    #   keypair.write_to('/var/lib/depot/storage/my-key.key')
    def self.generate
      keypair = new
      keypair.generate
      keypair
    end
  end
end