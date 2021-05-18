require "openssl"
require "digest"
require "msgpack"
require "uri"
require "log"
require "../*"

lib LibSSL
 fun ssl_ctx_use_rsaprivatekey_asn1 = SSL_CTX_use_RSAPrivateKey_ASN1(ctx : LibSSL::SSLContext, key : LibC::Char*, len : LibC::Long) : LibC::Int
 fun ssl_ctx_use_certificate_asn1 = SSL_CTX_use_certificate_ASN1(ctx : LibSSL::SSLContext, len : LibC::Int, cert : LibC::Char*) : LibC::Int
end

class OpenSSL::SSL::Context::Server
  def privatekey_s=(key : String)
    ret = LibSSL.ssl_ctx_use_rsaprivatekey_asn1(@handle,key,key.bytesize)
    raise OpenSSL::Error.new("SSL_CTX_use_RSAPrivateKey_ASN1") unless ret == 1
  end

  def cert_s=(cert : String)
    ret = LibSSL.ssl_ctx_use_certificate_asn1(@handle,cert.bytesize,cert)
    raise OpenSSL::Error.new("SSL_CTX_use_certificate_ASN1") unless ret == 1
  end
end


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
stored_backpack_digest = Bytes.new 64,0
f.read stored_backpack_digest

# read SHA512 digest of contents
stored_body_digest = Bytes.new 64,0
f.read stored_body_digest

Log.debug { "finding config & routing tree" }

# find end of header
r = f.gets("--like a backpack, but kitten sized--").not_nil!.to_slice
backpack_bytes = r[0,r.size-37]

Log.debug { "checking config, routing tree & body against hashes" }

backpack_digest = Digest::SHA512.new
backpack_digest << backpack_bytes
backpack_digest = backpack_digest.final

assert backpack_digest == stored_backpack_digest, "checksum for the kittn header section doesn't match - did the file get corrupted? :<"

backpack = Header.from_msgpack backpack_bytes
router = backpack.router

body_start = f.pos

body_digest = Digest::SHA512.new
body_digest << f.gets_to_end.to_slice
body_digest = body_digest.final

assert body_digest == stored_body_digest, "checksum for the kittn body section doesn't match - did the file get corrupted? :<"

Log.info { "starting kittn gemini server v0.0.1" }

if backpack.config.no_external_conf
  assert !backpack.config.cert.nil? && !backpack.config.key.nil?, "kittn was configured to not use any external files, but no certificates for SSL were packed ><"

  socket = TCPServer.new(1965)

  context = OpenSSL::SSL::Context::Server.new
  context.cert_s = backpack.config.cert.not_nil!
  context.privatekey_s = backpack.config.key.not_nil!
else
  kittn_conf = KittnConfig.from_yaml(File.read "kittn.yaml")
  server_conf = kittn_conf.server.not_nil!

  socket = TCPServer.new(server_conf.port)

  context = OpenSSL::SSL::Context::Server.new
  context.private_key = server_conf.key
  context.certificate_chain = server_conf.cert
end


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
      route = url.path[1..]
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
