# kittn
a gemini server that servers all your content from a single executable

## usage
first, set up a config like the one in the example folder.

then, run ./build.sh to pack the executable, which does the following
```bash
shards build # builds binaries
./bin/pack # packs content into executable
mv bin/server . # moves server to current dir
cat header.bin >>server # appends kittn header to server executable
cat body.bin >>server # appens kittn body to server executable
rm header.bin # remove header & body files
rm body.bin
```
you can then run the `server` binary, anywhere you want
(just remember to copy the cert and key!)

## fully single file mode (tls cert packing)
by default, kittn-server will look for a `kittn.yaml` file at runtime, which should contain a path to your SSL cert and key.

however, you can instead pack your SSL cert and key into the server binary itself at build-time, by making your `kittn.yaml` config the following:
```yaml
build:
  path: "webroot"
  no_external_conf: true
  certs:
    pack: true
    key: "key.der"
    cert: "cert.der"
```
note that the key and cert _must_ be in .der format.
