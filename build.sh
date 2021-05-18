#!/bin/bash
shards build --release
./bin/kittn-pack
mv bin/kittn-server .
cat header.bin >>kittn-server
cat body.bin >>kittn-server
rm header.bin
rm body.bin
