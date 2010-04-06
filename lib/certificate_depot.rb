require 'openssl'
require 'fileutils'

class CertificateDepot
  autoload :Certificate, 'certificate_depot/certificate'
  autoload :Keypair,     'certificate_depot/keypair'
  autoload :Runner,      'certificate_depot/runner'
  autoload :Store,       'certificate_depot/store'
  
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
  
  def generate_client_keypair_and_certificate(email_address)
    keypair     = CertificateDepot::Keypair.generate
    certificate = CertificateDepot::Certificate.generate(
      :ca_certificate => ca_certificate,
      :email_address => email_address,
      :public_key => keypair.public_key,
      :serial_number => certificates.next_serial_number
    )
    certificates << certificate
    certificates.sync
    [keypair, certificate]
  end
  
  def certificates
    @certificates ||= CertificateDepot::Store.new(self.class.certificates_path(path))
  end
  
  def self.create_directories(path)
    [
      private_path(path),
      certificates_path(path),
      crl_path(path)
    ].each do |directory|
      FileUtils.mkdir_p(directory)
    end
    FileUtils.chmod(0700, path)
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
    
    certificate = CertificateDepot::Certificate.generate(
      :public_key => keypair.public_key,
      :organization => label
    )
    certificate.write_to(certificate_path(path))
  end
  
  def self.create(path, label)
    create_directories(path)
    create_configuration(path, label)
    create_ca_certificate(path, label)
    new(path)
  end
  
  def self.generate_client_keypair_and_certificate(path, email)
    depot = new(path)
    depot.generate_client_keypair_and_certificate(email)
  end
  
  def self.configuration_example(path)
    "SSLEngine on
SSLOptions +StdEnvVars

SSLCertificateFile      \"#{certificate_path(path)}\"
SSLCertificateKeyFile   \"#{key_path(path)}\"

SSLVerifyClient require
SSLCACertificateFile    \"#{certificate_path(path)}\""
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