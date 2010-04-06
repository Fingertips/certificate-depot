class CertificateDepot
  class Store
    attr_accessor :path
    
    def initialize(path)
      @path         = path
      @certificates = []
      load
    end
    
    def size
      @certificates.size
    end
    
    def next_serial_number
      size + 1
    end
    
    def <<(certificate)
      @certificates << certificate
    end
    
    def sync
      @certificates.each do |certificate|
        certificate_path = File.join(@path, "#{certificate.serial_number}.crt")
        unless File.exist?(certificate_path)
          certificate.write_to(certificate_path)
        end
      end
    end
    
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