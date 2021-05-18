require "msgpack"
require "digest"

class TrieNode(T)
  include MessagePack::Serializable

  property leaves : Hash(UInt32,TrieNode(T))
  property value : T | Nil
  property final : Bool

  def initialize(@final = false, @leaves = Hash(UInt32,TrieNode(T)).new, @value = nil)
  end
end

class Trie(T)
  include MessagePack::Serializable

  property root : TrieNode(T)

  def initialize(@root = TrieNode(T).new)
  end

  def insert(word : String, value : T)
    cur = @root
    word.each_char do |c|
      c = c.unsafe_as(UInt32)
      next_node = cur.leaves[c]?
      if next_node == nil
        cur.leaves[c] = TrieNode(T).new
        cur = cur.leaves[c]
      else
        cur = next_node.as(TrieNode(T))
      end
    end

    cur.final = true
    cur.value = value
  end

  def search(word)
    cur = @root
    word.each_char do |c|
      c = c.unsafe_as(UInt32)
      next_node = cur.leaves[c]?
      if next_node == nil
        return nil
      else
        cur = next_node.as(TrieNode(T))
      end
    end

    cur.final ? cur.value.as(T) : nil
  end
end
