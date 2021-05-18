# kittn
a gemini server that servers all your content from a single executable

## usage
for everyday usage, you usually won't want to re-build the kittn binaries - you might not even have crystal installed, for example.

to use without compiling, first install the `kittn-server` and `kittn-pack` binaries to your path, and set up a config like the one in the example folder.

then, run `./pack.sh`, which make a copy of the kittn-server in your current directory, and add your content to it.

you can now run `./kittn-server` and acess your server at `gemini://localhost`!

## usage - building
first, set up a config like the one in the example folder.

then, run ./build.sh to pack the executable, which does the following
```bash
shards build --release # builds binaries
./bin/kittn-pack # packs content into executable
mv bin/kittn-server . # moves server to current dir
cat header.bin >>kittn-server # appends kittn header to server executable
cat body.bin >>kittn-server # appens kittn body to server executable
rm header.bin # remove header & body files
rm body.bin
```
you can then run the `kittn-server` binary, anywhere you want
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
