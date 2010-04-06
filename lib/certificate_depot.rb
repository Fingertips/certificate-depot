require 'openssl'
require 'fileutils'

class CertificateDepot
  autoload :Certificate, 'certificate_depot/certificate'
  autoload :Keypair,     'certificate_depot/keypair'
  autoload :Runner,      'certificate_depot/runner'
  
  def initialize(path)
    @config = OpenSSL::Config.load(self.class.openssl_config_path(path))
  end
  
  def label
    @config['ca']['default_ca']
  end
  
  def self.create_directories(path)
    [
      private_path(path),
      certificates_path(path),
      new_certificates_path(path),
      certificates_revokation_list_path(path)
    ].each do |directory|
      FileUtils.mkdir_p(directory)
    end
    FileUtils.chmod(0700, path)
  end
  
  def self.create_configuration(path, label)
    File.open(openssl_config_path(path), 'w') do |file|
      file.write("# Generated by Certificate Depot
[ ca ]
default_ca     = #{label}

[ #{label} ]
dir            = #{path}")
    end
  end
  
  def self.create_index(path)
    File.open(File.join(path, 'index.txt'), 'w')
  end
  
  def self.create_serial(path)
    File.open(File.join(path, 'serial'), 'w') { |file| file.write("01\n") }
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
    create_index(path)
    create_serial(path)
    create_ca_certificate(path, label)
    new(path)
  end
  
  def self.run(argv)
    runner = ::CertificateDepot::Runner.new(argv)
    runner.run
    runner
  end
  
  def self.openssl_config_path(path)
    File.join(path, 'openssl.cnf')
  end
  
  def self.private_path(path)
    File.join(path, 'private')
  end
  
  def self.certificates_path(path)
    File.join(path, 'certificates')
  end
  
  def self.new_certificates_path(path)
    File.join(path, 'new-certificates')
  end
  
  def self.certificates_revokation_list_path(path)
    File.join(path, 'crl')
  end
  
  def self.key_path(path)
    File.join(private_path(path), 'ca.key')
  end
  
  def self.certificate_path(path)
    File.join(certificates_path(path), 'ca.crt')
  end
end