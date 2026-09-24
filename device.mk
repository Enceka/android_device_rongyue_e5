#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# Allow Copy ELF from device 
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true

# Enable updating of APEXes
$(call inherit-product, $(SRC_TARGET_DIR)/product/updatable_apex.mk)

# A/B
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota.mk)
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS += \
    boot \
    init_boot \
    dtbo \
    vendor_boot \
    system \
    system_ext \
    product \
    vendor \
    odm \
    vendor_dlkm \
    vbmeta \
    vbmeta_system \
    vbmeta_vendor
BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT := true
BOARD_INCLUDE_RECOVERY_RAMDISK_IN_VENDOR_BOOT := true
PRODUCT_USE_DYNAMIC_PARTITIONS := true
PRODUCT_BUILD_SUPER_PARTITION := true

# Remove unwanted packages
PRODUCT_PACKAGES += \
    RemovePkgs

PRODUCT_PACKAGES += \
    android.hardware.boot@1.2-impl \
    android.hardware.boot@1.2-impl.recovery \
    android.hardware.boot@1.2-service

PRODUCT_PACKAGES += \
    update_engine \
    update_engine_sideload \
    update_verifier

PRODUCT_PACKAGES += \
    checkpoint_gc \
    otapreopt_script

# API levels
PRODUCT_SHIPPING_API_LEVEL := 33

# fastbootd
PRODUCT_PACKAGES += \
    android.hardware.fastboot@1.1-impl-mock \
    fastbootd

# Health
PRODUCT_PACKAGES += \
    android.hardware.health@2.1-impl \
    android.hardware.health@2.1-service

# Overlays
PRODUCT_ENFORCE_RRO_TARGETS := *

# Partitions
PRODUCT_USE_DYNAMIC_PARTITIONS := true

# Product characteristics
PRODUCT_CHARACTERISTICS := default

# Rootdir
PRODUCT_PACKAGES += \
    create_splloader_dual_slot_byname_path.sh \
    init.insmod.sh \
    speedrestrictor.sh \

PRODUCT_PACKAGES += \
    fstab.ums9158_1h10 \
    fstab.ums9621_1h10 \
    init.cali.rc \
    init.ram.gms.rc \
    init.ram.native.rc \
    init.ram.rc \
    init.storage.rc \
    init.ums9158_1h10.rc \
    init.ums9158_1h10.usb.rc \
    init.ums9621_1h10.rc \
    init.ums9621_1h10.usb.rc \

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/etc/fstab.ums9158_1h10:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/first_stage_ramdisk/fstab.ums9158_1h10 \
    $(LOCAL_PATH)/rootdir/etc/fstab.ums9621_1h10:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/first_stage_ramdisk/fstab.ums9621_1h10

# The recovery ramdisk
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/etc/fstab.ums9158_1h10:$(TARGET_COPY_OUT_RECOVERY)/root/first_stage_ramdisk/fstab.ums9158_1h10 \
    $(LOCAL_PATH)/rootdir/etc/fstab.ums9621_1h10:$(TARGET_COPY_OUT_RECOVERY)/root/first_stage_ramdisk/fstab.ums9621_1h10

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(LOCAL_PATH)

# Inherit the proprietary files
$(call inherit-product, vendor/rongyue/e5/e5-vendor.mk)
