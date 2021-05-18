#!/bin/bash
shards build
./bin/pack
mv bin/server .
cat header.bin >>server
cat body.bin >>server
rm header.bin
rm body.bin
