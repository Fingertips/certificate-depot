class CertificateDepot
  # Manages a directory with certificates. It's mainly used by the depot to
  # generate a unique serial for its certificates.
  class Store
    attr_accessor :path
    
    # Creates a new Store instance. The path should be a directory containing
    # certificates in PEM format.
    def initialize(path)
      @path         = path
      @certificates = []
      load
    end
    
    # Returns the number of certificates in the store.
    def size
      @certificates.size
    end
    
    # Returns an unused serial which can be used to generate a new certificate
    # for the store.
    def next_serial_number
      size + 1
    end
    
    # Append a certificate to the store.
    def <<(certificate)
      @certificates << certificate
    end
    
    # Writes all unsaved certificates to disk.
    def sync
      @certificates.each do |certificate|
        certificate_path = File.join(@path, "#{certificate.serial_number}.crt")
        unless File.exist?(certificate_path)
          certificate.write_to(certificate_path)
        end
      end
    end
    
    # Reads all certificates from disk.
    def load
      (Dir.entries(@path) - %w(. .. ca.crt)).each do |entry|
        certificate_path = File.join(@path, entry)
        self << CertificateDepot::Certificate.from_file(certificate_path)
      end
    end
    
    include Enumerable
    
    def each(&block)
      @certificates.each(&block)
    end
  end
end