require "digest"
require "msgpack"
require "uri"
require "log"
require "../*"

kittn_conf = KittnConfig.from_yaml(File.read "kittn.yaml")

Log.setup_from_env

def assert(condition,message)
  if !condition
    puts message
    exit 1
  end
end

f = File.open Process.executable_path.not_nil!, mode = "rb"

# seeks to the start of the header
f.gets(String.new(Bytes.new 8192, 0) + "++like a backpack, but kitten sized++")

f.seek -37, IO::Seek::Current

assert f.read_string(37) == "++like a backpack, but kitten sized++", "couldn't find kittn file storage section in this binary x.x"

Log.debug { "reading SHA512 hashes" }

# read SHA512 digest of pathing tree
stored_tree_digest = Bytes.new 64,0
f.read stored_tree_digest

# read SHA512 digest of contents
stored_body_digest = Bytes.new 64,0
f.read stored_body_digest

Log.debug { "finding routing tree" }

# find end of header
r = f.gets("--like a backpack, but kitten sized--").not_nil!.to_slice
tree_bytes = r[0,r.size-37]

Log.debug { "checking routing tree & body against hashes" }

tree_digest = Digest::SHA512.new
tree_digest << tree_bytes
tree_digest = tree_digest.final

assert tree_digest == stored_tree_digest, "checksum for the kittn header section doesn't match - did the file get corrupted? :<"

router = Trie(Document).from_msgpack tree_bytes

body_start = f.pos

body_digest = Digest::SHA512.new
body_digest << f.gets_to_end.to_slice
body_digest = body_digest.final

assert body_digest == stored_body_digest, "checksum for the kittn body section doesn't match - did the file get corrupted? :<"

Log.info { "starting kittn gemini server v0.0.1" }

socket = TCPServer.new(kittn_conf.server.port)

context = OpenSSL::SSL::Context::Server.new
context.private_key = kittn_conf.server.key
context.certificate_chain = kittn_conf.server.cert

while client = socket.accept?
  Log.debug { "got client!" }

  ssl_socket = OpenSSL::SSL::Socket::Server.new(client,context)

  url = URI.parse ssl_socket.gets.not_nil!

  Log.debug { "resolving request for #{url.to_s}" }

  route = ""

  if url.path == "/" || url.path == ""
    route = "index.gemini"
  else
    path = Path.posix url.path[1..]
    if path.extension.empty?
      route = (path / "index.gemini").to_s
    else
      route = url.path
    end
  end

  res = router.search route
  if res.nil?
    ssl_socket.write_utf8 "51 #{route} not found\r\n".encode("utf8")

    Log.debug {"51 #{route} not found"}
  else
    res = res.not_nil!
    f.read_at body_start + res.offset, res.size do |io|
      ssl_socket.write_utf8 "20 #{res.mime_type}\r\n".encode("utf8")
      IO.copy io, ssl_socket

      Log.debug {"20 sending response of type #{res.mime_type}"}
    end
  end

  ssl_socket.close
end
