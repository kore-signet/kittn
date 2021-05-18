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
