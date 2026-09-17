#
# Copyright (C) 2026 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
#
# The AOSP product base has to be inherited explicitly: LineageOS' own
# vendor/lineage/config/common*.mk only adds the Lineage packages on top and
# never pulls in build/make/target/product/base*.mk.  Without these two lines
# the product has ~160 packages instead of ~890 and no init/vendor base at all.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)
$(call inherit-product, device/rongyue/e5/device.mk)

# Device identifier
PRODUCT_NAME := lineage_e5
PRODUCT_DEVICE := e5
PRODUCT_BRAND := Rongyue
PRODUCT_MODEL := E5
PRODUCT_MANUFACTURER := Rongyue

PRODUCT_GMS_CLIENTID_BASE := android-unisoc

# Keep the OEM product identity in the build props: the Unisoc vendor HALs and
# the /odm firmware loaders key off ro.product.vendor.* / ro.product.odm.*.
PRODUCT_BUILD_PROP_OVERRIDES += \
    PRODUCT_NAME=ums9158_1h10_cmcc \
    PRODUCT_DEVICE=ums9158_1h10 \
    TARGET_DEVICE=ums9158_1h10

# The stock ROM reports this fingerprint; keep it so prebuilt vendor blobs that
# gate on ro.*.build.fingerprint keep working.  Update it (and the matching
# security patch level) whenever you move to a newer stock base.
BUILD_FINGERPRINT := UNISOC/ums9158_1h10_cmcc/ums9158_1h10:13/TP1A.220624.014/2026011323:user/release-keys
