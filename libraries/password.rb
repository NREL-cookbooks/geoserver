require "base64"
require "digest"
require "securerandom"

module Chef::Recipe::GeoServer
  def self.password_digest(password, salt = nil)
    salt ||= SecureRandom.random_bytes(16)

    hash = "#{salt}#{password}"
    100_000.times do
      hash = Digest::SHA256.new.digest(hash)
    end

    Base64.strict_encode64("#{salt}#{hash}")
  end

  def self.password_matches(digest, password)
    return false unless(digest)

    data = Base64.decode64(digest)
    salt = data[0,16]

    (digest == password_digest(password, salt))
  end
end
