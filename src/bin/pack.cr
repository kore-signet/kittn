require "../*"
require "mime"

MIME.register(".gemini","text/gemini")

kittn_conf = KittnConfig.from_yaml(File.read "kittn.yaml")
files = Dir.glob((Path.new kittn_conf.build.path) / "**" / "*").reject { |e| File.directory? e }.map { |e| e }

packed_conf = PackedConfig.new

if !kittn_conf.build.certs.nil? && kittn_conf.build.certs.not_nil!.pack
  cert_conf = kittn_conf.build.certs.not_nil!

  key_file = File.open cert_conf.key, mode: "rb"
  cert_file = File.open cert_conf.cert, mode: "rb"

  key = key_file.gets_to_end
  cert = cert_file.gets_to_end

  packed_conf.key = key
  packed_conf.cert = cert
end

packed_conf.no_external_conf = kittn_conf.build.no_external_conf

tree = Trie(Document).new
i = 0_u64

body = File.new("body.bin", mode="wb")

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

backpack = Header.new tree, packed_conf

backpack_bytes = backpack.to_msgpack

backpack_digest = Digest::SHA512.new
backpack_digest << backpack_bytes
backpack_digest = backpack_digest.final

header = File.new("header.bin", mode="wb")
header.sync = false

header.write Bytes.new(8192,0)
header.write "++like a backpack, but kitten sized++".encode("utf8")
header.write backpack_digest
header.write body_digest
header.write backpack_bytes
header.write "--like a backpack, but kitten sized--".encode("utf8")
header.close
