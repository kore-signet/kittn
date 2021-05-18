require "../*"
require "mime"

MIME.register(".gemini","text/gemini")

kittn_conf = KittnConfig.from_yaml(File.read "kittn.yaml")
files = Dir.glob((Path.new kittn_conf.build.path) / "**" / "*").reject { |e| File.directory? e }.map { |e| e }

body = File.new("body.bin", mode="wb")
tree = Trie(Document).new

i = 0_u64

files.each do |path|
  content = File.read path
  # this line is.. not great
  tree.insert (Path.new (Path.new path).parts[1..]).to_s, Document.new content.bytesize.to_u64, i, MIME.from_filename(path,"application/octet-stream")
  body.write content.to_slice

  i += content.bytesize.to_u64
end

body.close

body_digest = Digest::SHA512.new
body_digest.file "body.bin"
body_digest = body_digest.final

tree_bytes = tree.to_msgpack

tree_digest = Digest::SHA512.new
tree_digest << tree_bytes
tree_digest = tree_digest.final

header = File.new("header.bin", mode="wb")
header.sync = false

header.write Bytes.new(8192,0)
header.write "++like a backpack, but kitten sized++".encode("utf8")
header.write tree_digest
header.write body_digest
header.write tree_bytes
header.write "--like a backpack, but kitten sized--".encode("utf8")
header.close
