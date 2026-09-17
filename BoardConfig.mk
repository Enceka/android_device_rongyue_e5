#
# Copyright (C) 2026 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/rongyue/e5

# ---------------------------------------------------------------------------
# Architecture
#
# UMS9621 / qogirn6lite is a 4x Cortex-A55 + 4x Cortex-A55 SoC (armv8-2a).
# ---------------------------------------------------------------------------
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-2a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := cortex-a55

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-2a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := generic
TARGET_2ND_CPU_VARIANT_RUNTIME := cortex-a55

TARGET_SUPPORTS_64_BIT_APPS := true

# ---------------------------------------------------------------------------
# Platform / identity
#
# Verified on the real device (getprop):
#   ro.board.platform     = ums9621
#   ro.boot.hardware      = ums9158_1h10   <- this is what init uses to pick
#                                            init.<hardware>.rc and fstab.<hw>
#   ro.product.device     = ums9158_1h10
#   ro.build.fingerprint  = UNISOC/s9863a1h10_Natv/s9863a1h10:13/...
# ---------------------------------------------------------------------------
TARGET_BOARD_PLATFORM := ums9621
TARGET_BOOTLOADER_BOARD_NAME := ums9621_1h10
TARGET_OTA_ASSERT_DEVICE := e5,ums9158_1h10,ums9621_1h10

TARGET_NO_BOOTLOADER := true
TARGET_NO_RADIOIMAGE := true
TARGET_USES_UEFI := true
TARGET_USES_64_BIT_BINDER := true

# Required while the device tree is still being brought up: several
# LineageOS packages reference blobs that only exist once extract-files.sh
# has been run over a full system/vendor dump.
ALLOW_MISSING_DEPENDENCIES := true

# ---------------------------------------------------------------------------
# Kernel
#
# kernel_sprd_ums9158 (android13-5.15, 5.15.211) built in-tree.  The kernel
# build also produces the sprd dtbs/dtbos; the four BSP_* switches below are
# NOT Kconfig symbols -- arch/arm64/boot/dts/sprd/Makefile gates its whole
# dtb/dtbo list on them, and without them that Makefile takes its `else`
# branch and builds the ums9620-2h10 overlays instead.
# ---------------------------------------------------------------------------
TARGET_KERNEL_SOURCE := kernel/sprd/ums9158
TARGET_KERNEL_CONFIG := e5_rongyue_defconfig
TARGET_KERNEL_ARCH := arm64
TARGET_KERNEL_HEADER_ARCH := arm64
TARGET_KERNEL_CLANG_COMPILE := true
BOARD_KERNEL_IMAGE_NAME := Image

TARGET_KERNEL_ADDITIONAL_FLAGS += \
    CONFIG_DTB_ORIGINAL=y \
    BSP_BUILD_DT_OVERLAY=y \
    BSP_BUILD_ANDROID_OS=y \
    BSP_BUILD_FAMILY=qogirn6l

# ---------------------------------------------------------------------------
# Boot images
#
# Verified by parsing the header of the *stock* images (stock-img/*.img):
#
#   boot_a.img        magic ANDROID!, kernel_size 0x2c97000, ramdisk_size 0
#                     -> kernel-only, this is a GKI boot image
#   init_boot_a.img   magic ANDROID!, kernel_size 0, ramdisk_size 0x1bf526
#                     -> generic ramdisk only
#   vendor_boot_a.img magic VNDRBOOT, header_version 4, page_size 4096,
#                     kernel_addr 0x8000, ramdisk_addr 0x05400000,
#                     vendor_ramdisk_size 0x4ce9a61
#   dtb_a.img         all zeroes (the real dtb travels inside vendor_boot)
#   dtbo_a.img        populated (the bootloader applies it on top of the base)
#
# The vendor ramdisk was decompressed (lz4) and inspected: it carries
#   first_stage_ramdisk/fstab.ums9158_1h10
#   lib/modules/*.ko + modules.load + modules.load.recovery
# i.e. exactly the layout BOARD_VENDOR_RAMDISK_* / BOOT_KERNEL_MODULES produce.
# ---------------------------------------------------------------------------
BOARD_USES_GENERIC_KERNEL_IMAGE := true

BOARD_BOOT_HEADER_VERSION := 4
BOARD_KERNEL_PAGESIZE := 4096
BOARD_KERNEL_BASE := 0x00000000

# androidboot.selinux=permissive mirrors the stock ROM, which also runs
# permissive (`getenforce` -> Permissive on the stock build).  The Unisoc
# vendor policy is not available as source, so a handful of Unisoc-only
# domains (hal_codec2_unisoc, hal_cplog_svcaidl_default, hal_enhanceaidl_default,
# hal_logaidl_default, hal_networkaidl_default, hal_trustyclientaidl_default,
# hal_oemlock_default, hal_broadcastradio_ext, charger_vendor, tee, watchdogd)
# do not exist in a LineageOS-built policy and their services refuse to start
# while enforcing.  Drop this once those domains have been added under
# sepolicy/ (see README.md).
BOARD_KERNEL_CMDLINE := console=ttyS1,115200n8 bootconfig androidboot.selinux=permissive

BOARD_RAMDISK_OFFSET := 0x05400000
BOARD_KERNEL_TAGS_OFFSET := 0x00000100
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_MKBOOTIMG_ARGS += --ramdisk_offset $(BOARD_RAMDISK_OFFSET)
BOARD_MKBOOTIMG_ARGS += --tags_offset $(BOARD_KERNEL_TAGS_OFFSET)

# The vendor ramdisk on this device is lz4 (legacy) compressed.  The in-tree
# kernel therefore needs CONFIG_RD_LZ4=y, which e5_rongyue_defconfig sets.
BOARD_RAMDISK_USE_LZ4 := true

# boot.img carries no dtb (header v4 only writes a dtb for header v2); the
# bootloader takes it from vendor_boot.img.  Must be `true`, not merely
# defined: build/make checks `ifdef` for the dependency while the kernel task
# checks `ifeq (...,true)` for the rule that produces dtb.img.
BOARD_INCLUDE_DTB_IN_BOOTIMG := true
BOARD_KERNEL_SEPARATED_DTBO := true

# No dedicated recovery partition; recovery (Lineage recovery) shares the
# vendor ramdisk inside vendor_boot, exactly like the stock TWRP port did.
BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT := true

# ---------------------------------------------------------------------------
# Kernel modules
#
# The in-tree kernel build installs every .ko it produces into the vendor_dlkm
# image (BOARD_USES_VENDOR_DLKMIMAGE) and the first-stage subset into the
# vendor ramdisk (BOOT_KERNEL_MODULES).  Both load lists live in modules.load /
# modules.load.boot and are derived from the stock lists, filtered down to the
# modules e5_rongyue_defconfig actually builds -- see README.md.
# ---------------------------------------------------------------------------
BOARD_USES_VENDOR_DLKMIMAGE := true

BOARD_VENDOR_KERNEL_MODULES_LOAD := $(strip $(shell cat $(DEVICE_PATH)/modules.load))

BOOT_KERNEL_MODULES := $(strip $(shell cat $(DEVICE_PATH)/modules.load.boot))
BOARD_VENDOR_RAMDISK_KERNEL_MODULES_LOAD := $(strip $(shell cat $(DEVICE_PATH)/modules.load.boot))

# ---------------------------------------------------------------------------
# Partitions
#
# Sizes are the real values from `blockdev --getsize64` on the device.
# ---------------------------------------------------------------------------
BOARD_FLASH_BLOCK_SIZE := 262144

BOARD_BOOTIMAGE_PARTITION_SIZE := 67108864
BOARD_INIT_BOOT_IMAGE_PARTITION_SIZE := 8388608
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 104857600
BOARD_DTBOIMG_PARTITION_SIZE := 8388608

# ---------------------------------------------------------------------------
# Filesystems
#
# Stock mounts system/system_ext/product/vendor/odm/vendor_dlkm as erofs
# (verified in /proc/mounts).  fstab.ums9158_1h10 also carries an ext4
# alternative for /system, so switching system to ext4 below is safe.
# ---------------------------------------------------------------------------
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
TARGET_USES_MKE2FS := true
BOARD_USES_METADATA_PARTITION := true

BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_ODMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_VENDOR_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := f2fs

# Each partition above is a standalone logical partition in the stock layout, so
# the build has to stage it under its own top-level directory.  Whenever a
# BOARD_<part>IMAGE_FILE_SYSTEM_TYPE is set, board_config.mk requires the
# matching TARGET_COPY_OUT_<part> to name that partition; the default is the
# legacy 'system/<part>' subdirectory, and leaving it there aborts with
#   "TARGET_COPY_OUT_VENDOR must be set to 'vendor' to use a vendor image."
TARGET_COPY_OUT_VENDOR := vendor
TARGET_COPY_OUT_SYSTEM_EXT := system_ext
TARGET_COPY_OUT_PRODUCT := product
TARGET_COPY_OUT_ODM := odm
TARGET_COPY_OUT_VENDOR_DLKM := vendor_dlkm

# ---------------------------------------------------------------------------
# Dynamic partitions (super)
#
# 5872025600 bytes on the real device.  The group size keeps 4 MiB of headroom
# for the super metadata, same as the stock/verified TWRP configuration.
#
# `system_dlkm` is deliberately NOT in the list: it only ever holds GKI system
# modules, which this device does not use (its modules live in vendor_dlkm),
# and the stock system_dlkm logical partition is an empty 54 KiB filesystem.
# See README.md before adding it back.
# ---------------------------------------------------------------------------
BOARD_SUPER_PARTITION_SIZE := 5872025600
BOARD_SUPER_PARTITION_GROUPS := ums9621_dynamic_partitions
BOARD_UMS9621_DYNAMIC_PARTITIONS_PARTITION_LIST := system system_ext product vendor odm vendor_dlkm
BOARD_UMS9621_DYNAMIC_PARTITIONS_SIZE := 5867831296

# ---------------------------------------------------------------------------
# Recovery (Lineage recovery lives in the vendor_boot ramdisk)
# ---------------------------------------------------------------------------
BOARD_HAS_LARGE_FILESYSTEM := true
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery/root/system/etc/recovery.fstab

# ---------------------------------------------------------------------------
# Treble / VNDK
# ---------------------------------------------------------------------------
BOARD_VNDK_VERSION := current

# ---------------------------------------------------------------------------
# VINTF
#
# The stock device manifests are kept in-tree (configs/vintf/) instead of being
# pulled as blobs, because the build assembles DEVICE_MANIFEST_FILE into
# $(TARGET_OUT_VENDOR)/etc/vintf/manifest.xml and a second copy would collide.
# configs/vintf/manifest_odm.xml carries the odm overrides
# (fingerprint / tui / soter / fingerprintmmi are `override="true"`).
# ---------------------------------------------------------------------------
DEVICE_MANIFEST_FILE := \
    $(DEVICE_PATH)/configs/vintf/manifest.xml \
    $(DEVICE_PATH)/configs/vintf/manifest_odm.xml

# ---------------------------------------------------------------------------
# Verified boot
#
# The device is unlocked and stock already runs with verification disabled
# (androidboot.verifiedbootstate=orange, androidboot.veritymode=disabled), so
# vbmeta is built with --flags 3 (hashtree + verification both disabled) and
# signed with the AOSP test key.  Chain partitions mirror the stock layout
# (vbmeta_system -> system/system_ext/product, vbmeta_vendor -> vendor/odm).
#
# If the Unisoc bootloader ever rejects a test-key vbmeta, set
# BOARD_AVB_ENABLE := false and flash boot/init_boot/vendor_boot/dtbo + super
# individually -- the device boots fine without AVB at all.
# ---------------------------------------------------------------------------
BOARD_AVB_ENABLE := true
BOARD_AVB_ALGORITHM := SHA256_RSA2048
BOARD_AVB_KEY_PATH := external/avb/test/data/testkey_rsa2048.pem
BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 3

BOARD_AVB_VBMETA_SYSTEM := system system_ext product
BOARD_AVB_VBMETA_SYSTEM_KEY_PATH := external/avb/test/data/testkey_rsa2048.pem
BOARD_AVB_VBMETA_SYSTEM_ALGORITHM := SHA256_RSA2048
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX_LOCATION := 1

BOARD_AVB_VBMETA_VENDOR := vendor odm
BOARD_AVB_VBMETA_VENDOR_KEY_PATH := external/avb/test/data/testkey_rsa2048.pem
BOARD_AVB_VBMETA_VENDOR_ALGORITHM := SHA256_RSA2048
BOARD_AVB_VBMETA_VENDOR_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_VBMETA_VENDOR_ROLLBACK_INDEX_LOCATION := 2

# ---------------------------------------------------------------------------
# Display
#
# Physical panel is 320x480; the stock ROM overrides the (105 dpi) physical
# density to 150 (`wm density` reports "Physical density: 105 / Override
# density: 150").  Keep 150 so the stock UI proportions are preserved.
# ---------------------------------------------------------------------------
TARGET_SCREEN_HEIGHT := 480
TARGET_SCREEN_WIDTH := 320
TARGET_SCREEN_DENSITY := 150

# ---------------------------------------------------------------------------
# Properties
#
# The stock vendor/odm build.prop is not extracted (the build regenerates it)
# and is not readable over adb, so the device properties it carried -- notably
# the ro.hardware.<class> names the HAL loader uses to pick the vendor module,
# and the modem / camera / WCN device nodes -- have to be declared explicitly.
# See configs/properties/.
# ---------------------------------------------------------------------------
TARGET_VENDOR_PROP += $(DEVICE_PATH)/configs/properties/vendor.prop
TARGET_VENDOR_PROP += $(DEVICE_PATH)/configs/properties/vendor_persist.prop
TARGET_ODM_PROP += $(DEVICE_PATH)/configs/properties/odm.prop

# ---------------------------------------------------------------------------
# Debug
# ---------------------------------------------------------------------------
TARGET_USES_LOGD := true
