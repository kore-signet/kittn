#!/bin/bash
cp $(command -v kittn-server) .
kittn-pack
cat header.bin >>kittn-server
cat body.bin >>kittn-server
rm header.bin body.bin
