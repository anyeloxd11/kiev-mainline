#!/bin/bash
# Kiev Boot Image Repack Script
source ./scripts/env_setup.sh

KIEV_ROOT=./Kiev/
OUT_DIR="$KIEV_ROOT/kernel/kernel"
BOOT_IMG="$KIEV_ROOT/boot.img"
DTB="$OUT_DIR/arch/arm64/boot/dts/qcom/sm7225-motorola-kiev.dtb"
RAMDISK="$KIEV_ROOT/initramfs.cpio.gz"

echo "--- Making boot.img ---"

# Parameters
BASE="0x00000000"
PAGESIZE="4096"
KERNEL_OFFSET="0x00008000"
RAMDISK_OFFSET="0x01000000"
TAGS_OFFSET="0x00000100"
HEADER_VERSION="2"

# 1. Packing Initramfs
if [ ! -f "$RAMDISK" ]; then
    ./$KIEV_ROOT/scripts/pack_initramfs.sh
fi

# 2. Verify Kernel
if [ ! -f "$OUT_DIR/arch/arm64/boot/Image.gz" ]; then
    echo "Error: Image.gz not found in $OUT_DIR. Compile kernel first."
    exit 1
fi

# 3. Packing boot.img
mkbootimg.py \
    --kernel "$OUT_DIR/arch/arm64/boot/Image.gz" \
    --ramdisk "$RAMDISK" \
    --dtb "$DTB" \
    --base "$BASE" \
    --pagesize "$PAGESIZE" \
    --kernel_offset "$KERNEL_OFFSET" \
    --ramdisk_offset "$RAMDISK_OFFSET" \
    --tags_offset "$TAGS_OFFSET" \
    --header_version "$HEADER_VERSION" \
    -o "$BOOT_IMG"

if [ $? -eq 0 ]; then
    echo "Success: $BOOT_IMG."
else
    echo "Error in mkbootimg."
fi
