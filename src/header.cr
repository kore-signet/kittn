require "msgpack"
require "./trie.cr"
require "./config.cr"

struct Document
  include MessagePack::Serializable

  property mime_type : String
  property offset : UInt64
  property size : UInt64

  def initialize(@size,@offset,@mime_type)
  end
end

struct Header
  include MessagePack::Serializable
  property router : Trie(Document)
  property config : PackedConfig

  def initialize(@router,@config) end
end
