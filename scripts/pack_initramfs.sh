#!/bin/bash

# initramfs directory
SOURCE_DIR="/Kiev/initramfs"
# output file name
OUTPUT_FILE="/Kiev/initramfs.cpio.gz"

echo "Packing initramfs from $SOURCE_DIR"

# Entering the directory for making rutes of cpio be relatives to the source dir
cd "$SOURCE_DIR" || exit

# 1. Giving permission to init file
chmod +x init
# 2. Making CPIO and compressing with gzio
# -H newc is the header format that kernel requires
find . | cpio -H newc -o | gzip > "$OUTPUT_FILE"

echo "initramfs maked in $OUTPUT_FILE"
