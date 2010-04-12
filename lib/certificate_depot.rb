require 'openssl'
require 'fileutils'

class CertificateDepot
  autoload :Certificate, 'certificate_depot/certificate'
  autoload :Keypair,     'certificate_depot/keypair'
  autoload :Runner,      'certificate_depot/runner'
  autoload :Server,      'certificate_depot/server'
  autoload :Store,       'certificate_depot/store'
  autoload :Worker,      'certificate_depot/worker'
  
  def initialize(path)
    @config = OpenSSL::Config.load(self.class.openssl_config_path(path))
  end
  
  def label
    @config['ca']['label']
  end
  
  def path
    @config[label]['path']
  end
  
  def ca_certificate
    @ca_certificate ||= CertificateDepot::Certificate.from_file(self.class.certificate_path(path))
  end
  
  def ca_private_key
    @ca_private_key ||= OpenSSL::PKey::RSA.new(File.read(self.class.key_path(path)))
  end
  
  def generate_keypair_and_certificate(options={})
    keypair     = CertificateDepot::Keypair.generate
    
    attributes = options
    attributes[:ca_certificate] = ca_certificate
    attributes[:public_key]     = keypair.public_key
    attributes[:private_key]    = ca_private_key
    attributes[:serial_number]  = certificates.next_serial_number
    certificate = CertificateDepot::Certificate.generate(attributes)
    
    certificates << certificate
    certificates.sync
    
    [keypair, certificate]
  end
  
  def certificates
    @certificates ||= CertificateDepot::Store.new(self.class.certificates_path(path))
  end
  
  def self.create_directories(path)
    FileUtils.mkdir_p(certificates_path(path))
    FileUtils.mkdir_p(private_path(path))
    FileUtils.chmod(0700, private_path(path))
    FileUtils.chmod(0755, path)
  end
  
  def self.create_configuration(path, label)
    File.open(openssl_config_path(path), 'w') do |file|
      file.write("[ ca ]
label           = #{label}

[ #{label} ]
path            = #{path}
")
    end
  end
  
  def self.create_ca_certificate(path, label)
    keypair = CertificateDepot::Keypair.generate
    keypair.write_to(key_path(path))
    
    attributes = {}
    attributes[:type]         = :ca
    attributes[:public_key]   = keypair.public_key
    attributes[:private_key]  = keypair.private_key
    attributes[:organization] = label
    certificate = CertificateDepot::Certificate.generate(attributes)
    certificate.write_to(certificate_path(path))
  end
  
  def self.create(path, label, options={})
    attributes = options
    create_directories(path)
    create_configuration(path, label)
    create_ca_certificate(path, label)
    new(path)
  end
  
  def self.generate_keypair_and_certificate(path, options={})
    depot = new(path)
    depot.generate_keypair_and_certificate(options)
  end
  
  def self.configuration_example(path)
    "SSLEngine on
SSLOptions +StdEnvVars
SSLCertificateFile      \"/etc/apache/ssl/certificates/example.com.pem\"
SSLVerifyClient require
SSLCACertificateFile    \"#{certificate_path(path)}\""
  end
  
  def self.listen(path, options={})
    CertificateDepot::Server.listen(new(path), options)
  end
  
  def self.shutdown
    CertificateDepot::Server.kill
  end
  
  def self.run(argv)
    runner = ::CertificateDepot::Runner.new(argv)
    runner.run
    runner
  end
  
  def self.openssl_config_path(path)
    File.join(path, 'depot.cnf')
  end
  
  def self.private_path(path)
    File.join(path, 'private')
  end
  
  def self.certificates_path(path)
    File.join(path, 'certificates')
  end
  
  def self.crl_path(path)
    File.join(path, 'crl.pem')
  end
  
  def self.key_path(path)
    File.join(private_path(path), 'ca.key')
  end
  
  def self.certificate_path(path)
    File.join(certificates_path(path), 'ca.crt')
  end
end