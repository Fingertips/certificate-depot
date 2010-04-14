require 'openssl'
require 'fileutils'

# = CertificateDepot
#
# The CertificateDepot manages a single depot of certificates. For more than a
# casual understanding of these terms we need to explain a bit more about
# certificates first. If you already know how PKI works, you can skip the
# following paragraphs.
#
# == Certificate Authorities
#
# “[A] certificate authority or certification authority (CA) is an entity that
# issues digital certificates for use by other parties.”
# – http://en.wikipedia.org/wiki/Certificate_authority
#
# When a CA says that party A is who they say they are and you trust the CA 
# then you can assume they are in fact party A.
#
# In a Public Key Infrastructure this means that the CA has a private key
# which only he knows. He uses this key to sign certificates stating that the # person owning the certificate is who the certificate says they are. Because # there is a public key associated with the certificate anyone can use a
# crytographic challenge to make sure the owner has the private key to this
# certificate.
#
# For example: I have a certificate that says that I'm the person with the
# email address robert@example.com. I show my certificate to Rick. Rick gets
# my public key from the certificate and sends me a challenge. I compute the
# right response and send it to Rick. Rick checks the response and knows I'm
# the rightful owner of the certificate.
#
# A PKI infrastructure has many more uses, but we will only focus on
# authentication in our examples.
#
# There are two ways in which a CA can make sure his trust network stays
# valid. Each certificate has a limited period in which it's valid. Even if
# the CA forgets that he has issued the certificate it will stop being valid
# after a while. Large CA's claim this also protects against evolving
# attack vectors against the crytography used behind the certificates. Each
# certificate can be _revoked_ by the CA. A publicly available list of
# revoked certificates makes it possible to check whether a certain
# certificate is still valid according to the CA.
#
# == Certificate types
#
# Certificate authorities came up with lots of additional features. One of
# these is a certificate type. To be more precise, there is an extension
# to the certificate that tells in which cases you should accept the key
# contained in the certificate. This allows the CA to limit the use of a
# certificate to just digital signatures, encipherment, or certain types
# of authentication.
#
# For simplicity Certificate Depot only knows three types; CA, Server, and
# Client.
#
# == A certificate depot
#
# We've named the collection of all information needed to run a CA a
# certificate depot. It holds the CA certificate and private key, all issued
# certificates, the revokation list, and several files need to manage these.
class CertificateDepot
  autoload :Certificate, 'certificate_depot/certificate'
  autoload :Keypair,     'certificate_depot/keypair'
  autoload :Log,         'certificate_depot/log'
  autoload :Runner,      'certificate_depot/runner'
  autoload :Server,      'certificate_depot/server'
  autoload :Store,       'certificate_depot/store'
  autoload :Worker,      'certificate_depot/worker'
  
  # Initialize a new depot with the path to the depot directory.
  #
  #   depot = CertificateDepot.new('/var/lib/certificate-depot/example')
  def initialize(path)
    @config = OpenSSL::Config.load(self.class.openssl_config_path(path))
  end
  
  # Returns the label with a descriptive name for the depot. This is usually
  # the common name of the CA.
  def label
    @config['ca']['label']
  end
  
  # Path to the depot directory.
  def path
    @config[label]['path']
  end
  
  # Returns an instance of CertificateDepot::Certificate containing the
  # certificate of the certificate authority.
  def ca_certificate
    @ca_certificate ||= CertificateDepot::Certificate.from_file(self.class.certificate_path(path))
  end
  
  # Returns an instance of OpenSSL::PKey::RSA containing the private key
  # of the certificate authority.
  def ca_private_key
    @ca_private_key ||= OpenSSL::PKey::RSA.new(File.read(self.class.key_path(path)))
  end
  
  # Generates a new RSA keypair and certificate.
  #
  # === Defaults
  #
  # By default the certificate issuer is the CA of the depot and it's also
  # signed by the CA. The serial number is the next available serial number
  # in the depot.
  #
  # See CertificateDepot::Certificate#generate for all available options.
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
  
  # Returns an instance of CertificateDepot::Store representing all
  # certificates in the depot.
  def certificates
    @certificates ||= CertificateDepot::Store.new(self.class.certificates_path(path))
  end
  
  def self.create_directories(path)
    FileUtils.mkdir_p(certificates_path(path))
    FileUtils.mkdir_p(private_path(path))
    FileUtils.chmod(0700, private_path(path))
    FileUtils.chmod(0755, path)
  end
  
  # Writes a configuration file to disk containing the path to the depot
  # and its name.
  def self.create_configuration(path, label)
    File.open(openssl_config_path(path), 'w') do |file|
      file.write("[ ca ]
label           = #{label}

[ #{label} ]
path            = #{path}
")
    end
  end
  
  # Creates a CA certificate and keypair and writes it to disk.
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
  
  # Creates a new depot on disk.
  #
  #   depot = CertificateDepot.create('/var/lib/certificate-depot/example')
  def self.create(path, label, options={})
    attributes = options
    create_directories(path)
    create_configuration(path, label)
    create_ca_certificate(path, label)
    new(path)
  end
  
  # Generates a new RSA keypair and certificate. See
  # CertificateDepot#generate_keypair_and_certificate and
  # CertificateDepot::Certificate.new for more information and possible
  # options.
  #
  #   keypair, certificate = 
  #     CertificateDepot.generate_keypair_and_certificate(
  #       '/var/lib/certificate-depot/example', {
  #         :type => :client,
  #         :common_name => 'Robert Verkey',
  #         :email_address => 'robert@example.com'
  #       }
  #     )
  def self.generate_keypair_and_certificate(path, options={})
    depot = new(path)
    depot.generate_keypair_and_certificate(options)
  end
  
  # Returns a string with an Apache configuration example for using TLS
  # client certificate authentication.
  def self.configuration_example(path)
    "SSLEngine on
SSLOptions +StdEnvVars
SSLCertificateFile      \"/etc/apache/ssl/certificates/example.com.pem\"
SSLVerifyClient require
SSLCACertificateFile    \"#{certificate_path(path)}\""
  end
  
  # Starts a server. For available options see CertificateDepot::Server.new.
  def self.start(path, options={})
    CertificateDepot::Server.start(new(path), options)
  end
  
  # Stops a running server. Using the options you can specify where to look
  # for the pid file. See CertificateDepot::Server.new for more information
  # about the options.
  def self.stop(options={})
    CertificateDepot::Server.stop(options)
  end
  
  # Runs a command to the depot. Used by the command line tool to run
  # commands.
  def self.run(argv)
    runner = ::CertificateDepot::Runner.new(argv)
    runner.run
    runner
  end
  
  # Returns the path to the configuration file given the depot path.
  def self.openssl_config_path(path)
    File.join(path, 'depot.cnf')
  end
  
  # Returns the path to the directory with private data given the depot path.
  def self.private_path(path)
    File.join(path, 'private')
  end
  
  # Returns the path to the generated certificates given the depot path.
  def self.certificates_path(path)
    File.join(path, 'certificates')
  end
  
  # Returns the path to the certificate revokation list given the depot path.
  def self.crl_path(path)
    File.join(path, 'crl.pem')
  end
  
  # Returns the path to the CA's private key given the depot path.
  def self.key_path(path)
    File.join(private_path(path), 'ca.key')
  end
  
  # Returns the path to the CA's certificate given the depot path.
  def self.certificate_path(path)
    File.join(certificates_path(path), 'ca.crt')
  end
end