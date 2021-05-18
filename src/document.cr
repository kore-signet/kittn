require "msgpack"

struct Document
  include MessagePack::Serializable

  property mime_type : String
  property offset : UInt64
  property size : UInt64

  def initialize(@size,@offset,@mime_type)
  end
end
