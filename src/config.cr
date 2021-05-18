require "msgpack"
require "yaml"

struct KittnConfig
  include YAML::Serializable
  property build : BuildConfig
  property server : ServerConfig?
end

struct BuildConfig
  include YAML::Serializable
  property path : String
  property no_external_conf : Bool = false
  property certs : CertConfig?
end

struct CertConfig
  include YAML::Serializable
  property pack : Bool = true
  property key : String
  property cert : String
end

struct ServerConfig
  include YAML::Serializable
  property port : Int32 = 1965
  property key : String
  property cert : String
end

struct PackedConfig
  include MessagePack::Serializable
  property key : String? = nil
  property cert : String? = nil
  property no_external_conf : Bool = false

  def initialize()

  end
end
