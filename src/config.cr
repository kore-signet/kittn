require "yaml"

class KittnConfig
  include YAML::Serializable
  property build : BuildConfig
  property server : ServerConfig
end

class BuildConfig
  include YAML::Serializable
  property path : String
end

class ServerConfig
  include YAML::Serializable
  property port : Int32 = 1965
  property key : String
  property cert : String
end
