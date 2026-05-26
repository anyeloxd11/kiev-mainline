# Development and Build Guide

This document details the technical specifics for building and packaging the mainline kernel for Motorola Kiev.

## Build Environment

- **Kernel Tree**: [Linux Mainline](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git) (or compatible fork).
- **Arch**: `arm64`
- **Cross Compiler**: `aarch64-linux-gnu-`
- **CC**: `clang`

## Building the Kernel

1. Use the provided `kiev_defconfig` (found in `configs/`).
2. You must add sm7225-motorola-kiev.dts to arch/arm64/boot/dts/qcom/Makefile as: 

```
dtb-$(CONFIG_ARCH_QCOM)	+= sm7225-motorola-kiev.dtb
```

3. Build the image and DTB:
   ```bash
   make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 DTC_FLAGS="-@" -j$(nproc) Image.gz dtbs
   ```

## Packaging (mkbootimg)

The Motorola ABL (Android Bootloader) requires specific offsets and header versions. Use the following parameters with `mkbootimg`:

```bash
mkbootimg \
  --kernel Image.gz \
  --ramdisk initramfs.cpio.gz \
  --dtb sm7225-motorola-kiev.dtb \
  --base 0x00000000 \
  --pagesize 4096 \
  --kernel_offset 0x00008000 \
  --ramdisk_offset 0x01000000 \
  --tags_offset 0x00000100 \
  --header_version 2 \
  -o boot.img
```

You must have a proper initramfs.cpio.gz to include in the packaging of the boot.img. It is recommended to include a static arm64 busybox binary for the early stages of development. You may also need to include an init script for mounting necessary systems like debugfs, configfs, etc., and spawning a shell on ttyMSM0.


## The Purged DTBO

The stock Motorola DTBO is ~8MB and contains PMIC configurations that conflict with the mainline kernel's SPMI management. 

We use a **"Purged DTBO"** (~3KB) that only contains the bare minimum required by the ABL to avoid hangs:
- `mmi,utags` partitions.
- Early reserved memory regions (`ramoops`, `tzlog`).
- Basic model/compatible strings.

The source for this DTBO is located at `dtbo/overlay.dts`.

## Commands for DTBO Creation
```bash
dtc -@ -I dts -O dtb -o overlay.dtbo overlay.dts
```

```bash
./libufdt/utils/src/mkdtboimg.py create dtbo.img overlay.dtbo
```
## UART Debugging

- **Voltage**: 1.8V
- **Baudrate**: 115200n8
- **Pins**: TX and RX are both necessary.
- **ABL Logs**: If only the RX pin is connected, you cannot see the ABL (Android Bootloader) logs; both TX and RX must be connected to receive ABL logs.

## Mandatory Cmdline (bootargs)

The following parameters are required in the Device Tree (`chosen` node) or via `mkbootimg`:
```bash
console=ttyMSM0,115200n8 earlycon=qcom_geni,0x98c000 cpuidle.off=1 ro init=/init
```
- `cpuidle.off=1`: Prevents early boot hangs due to PSCI/Idle issues.


## Flashing the boot.img

You need the fastboot command for flashing the boot.img with:

```bash
fastboot flash boot boot.img
```
You can flash boot.img in any of A/B slots. It is recommended to flash it to slot B and maintain a proper rooted Android boot.img in slot A for debugging with the stock kernel via adb shell. This is useful for gathering information from the running Android system and analyzing it.

The commands for setting the active slot are:

```bash
fastboot set_active a
fastboot set_active b
```

If you flash the mainline boot.img to slot B, you must also flash the purged DTBO to make the boot.img acceptable for ABL verification using:

```bash
fastboot flash dtbo purged_dtbo.img
```

for slot B. You must do the same with the stock dtbo.img in slot A to make Android boot properly.
