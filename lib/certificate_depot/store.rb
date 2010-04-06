class CertificateDepot
  class Store
    attr_accessor :path
    
    def initialize(path)
      @path         = path
      @certificates = []
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
  end
end