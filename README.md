# LineageOS 20 device tree — Rongyue E5 (Unisoc UMS9621 / qogirn6lite)

LineageOS 20 (Android 13) device tree for the **Rongyue E5**, a 5G MiFi / pocket
router built on the Unisoc **UMS9158 / UMS9621** (qogirn6lite) platform.

| | |
|---|---|
| Device tree directory | `device/rongyue/e5` |
| Repository name | `android_device_rongyue_e5` |
| Product | `ums9158_1h10_cmcc` |
| Device / board | `ums9158_1h10` / `ums9621_1h10` |
| SoC | Unisoc UMS9621 (qogirn6lite), 4×A55 + 4×A55 |
| RAM / storage | 2 GB / 64 GB (`ro.boot.ddrsize=2048M`) |
| Display | 320×480, density 150 |
| Stock OS | Android 13 (TP1A.220624.014, `ro.board.first_api_level=33`) |
| Kernel | 5.15.211 (GKI, header v4), built from `kernel_sprd_ums9158` |
| Partitioning | A/B, dynamic partitions (`super`), no recovery partition |
| SELinux | permissive (stock is permissive too) |

Everything in this tree was derived from the real device (adb root) and from
binary/header analysis of the stock images — the source of each value is noted
inline. See [Verification notes](#verification-notes) for the raw evidence.

---

## 1. Layout

```
device/rongyue/e5/
├── AndroidProducts.mk          # lunch combos
├── BoardConfig.mk              # everything hardware specific
├── device.mk                   # products, packages, first-stage fstab
├── lineage_e5.mk               # product definition
├── lineage.dependencies        # pulls in the kernel repo
├── extract-files.sh            # -> vendor/rongyue/e5 (blobs)
├── setup-makefiles.sh          # regenerates the vendor makefiles only
├── proprietary-files.txt       # 3631 blobs: vendor + odm + system_ext + system
├── modules.load                # vendor_dlkm module load order (155 entries)
├── modules.load.boot           # first-stage modules for the vendor ramdisk (42)
├── configs/
│   ├── fstab/fstab.ums9158_1h10        # -> first_stage_ramdisk/fstab.<hw>
│   └── vintf/manifest.xml              # stock /vendor manifest (DEVICE_MANIFEST_FILE)
│       vintf/manifest_odm.xml          # stock /odm manifest overrides
└── recovery/root/system/etc/recovery.fstab
```

`DEVICE_PATH` is `device/rongyue/e5`, so this repository must be reachable at
that path (clone or symlink).

---

## 2. Getting the sources

LineageOS 20 (`lineage-20.0`) is the matching branch: the device shipped with
Android 13 / API 33, and the kernel is `android13-5.15`, so a 12.1 (LOS 19.1) or
14 (LOS 21) base would only add friction.

```sh
# 1. LineageOS 20 tree
repo init -u https://github.com/LineageOS/android.git -b lineage-20.0 --git-lfs
repo sync -c -j"$(nproc --all)" --force-sync --no-clone-bundle --no-tags

# 2. This device tree
git clone <this-repo> device/rongyue/e5

# 3. The kernel, at the path BoardConfig.mk expects
git clone <kernel_sprd_ums9158-repo> kernel/sprd/ums9158
```

`lineage.dependencies` records the kernel so `breakfast e5` / the LineageOS
build servers fetch it automatically:

```json
[ { "repository": "android_kernel_sprd_ums9158",
    "target_path": "kernel/sprd/ums9158" } ]
```

---

## 3. Pulling the blobs

`BoardConfig.mk` also works with `TARGET_KERNEL_SOURCE` pointing at the kernel
tree already present in this workspace (`kernel_ts305_ums9158`); just make sure
`kernel/sprd/ums9158` resolves to it and that
`arch/arm64/configs/e5_rongyue_defconfig` is in place.

```sh
cd device/rongyue/e5
./extract-files.sh            # pulls from the connected device over adb
# or, from a dump:
./extract-files.sh /path/to/dump
```

This produces `vendor/rongyue/e5/` (~3.6k blobs) plus the generated makefiles
`e5-vendor.mk`, `Android.bp`, `Android.mk`, `BoardConfigVendor.mk`.

### What is *not* extracted, and why

| Skipped | Reason |
|---|---|
| `/vendor_dlkm/**` | rebuilt by the in-tree kernel; `modules.load` drives it |
| `/system/**` except the 6 Unisoc framework files | rebuilt from LineageOS sources |
| `/product/**` | stock GMS apps; LineageOS ships its own |
| `build.prop`, `etc/fs_config_*`, `etc/passwd`, `etc/group`, `etc/NOTICE.xml.gz` | regenerated per partition by the build |
| `etc/vintf/**` | kept in-tree (`configs/vintf/`) and wired through `DEVICE_MANIFEST_FILE` |
| `etc/selinux/**` | regenerated per partition by the build — see [§7](#7-known-issues--todo) |
| `**/oat/**`, `*.odex`, `*.vdex`, `*.art`, `*.oat`, `*.prof` | stale prebuilt dex; regenerated on first boot |

---

## 4. Building

```sh
source build/envsetup.sh
lunch lineage_e5-userdebug        # use userdebug while bringing the port up
mka bacon
```

Outputs in `out/target/product/e5/`:

```
boot.img         kernel only           (GKI header v4)
init_boot.img    generic ramdisk
vendor_boot.img  vendor ramdisk + fstab + first-stage modules + dtb + recovery
dtbo.img         device tree overlays
super.img        system + system_ext + product + vendor + odm + vendor_dlkm
vbmeta.img, vbmeta_system.img, vbmeta_vendor.img
lineage-20.0-…-e5.zip
```

### Flashing

```sh
adb reboot bootloader

fastboot flash boot        out/target/product/e5/boot.img
fastboot flash init_boot   out/target/product/e5/init_boot.img
fastboot flash vendor_boot out/target/product/e5/vendor_boot.img
fastboot flash dtbo        out/target/product/e5/dtbo.img

fastboot flash vbmeta        out/target/product/e5/vbmeta.img
fastboot flash vbmeta_system out/target/product/e5/vbmeta_system.img
fastboot flash vbmeta_vendor out/target/product/e5/vbmeta_vendor.img

# super needs fastbootd
fastboot reboot fastboot
fastboot flash system     out/target/product/e5/system.img
fastboot flash system_ext out/target/product/e5/system_ext.img
fastboot flash product    out/target/product/e5/product.img
fastboot flash vendor     out/target/product/e5/vendor.img
fastboot flash odm        out/target/product/e5/odm.img
fastboot flash vendor_dlkm out/target/product/e5/vendor_dlkm.img
```

> **Keep a stock backup first.** `dd` `boot_a`, `init_boot_a`, `vendor_boot_a`,
> `dtbo_a`, `vbmeta*` and the whole of `super` off the device before flashing
> anything.

Partition sizes are all real values from `blockdev --getsize64`:

| partition | bytes |
|---|---|
| `boot` | 67108864 |
| `init_boot` | 8388608 |
| `vendor_boot` | 104857600 |
| `dtbo` | 8388608 |
| `super` | 5872025600 |
| `super` group | 5867831296 (4 MiB reserved for metadata) |
| `metadata` | 67108864 |
| `userdata` | 23467130880 |

---

## 5. Kernel integration

`kernel_sprd_ums9158` is built in-tree:

```make
TARGET_KERNEL_SOURCE := kernel/sprd/ums9158
TARGET_KERNEL_CONFIG := e5_rongyue_defconfig
TARGET_KERNEL_ADDITIONAL_FLAGS += \
    CONFIG_DTB_ORIGINAL=y BSP_BUILD_DT_OVERLAY=y BSP_BUILD_ANDROID_OS=y BSP_BUILD_FAMILY=qogirn6l
```

The four `BSP_*` switches are **not** Kconfig symbols. `arch/arm64/boot/dts/sprd/Makefile`
gates its entire dtb/dtbo list on them as make variables; without them that
Makefile takes its `else` branch and builds the `ums9620-2h10` overlays instead,
so neither `ums9621-base.dtb` nor `e5-rongyue-overlay.dtbo` is produced.

Module plumbing:

* `BOARD_USES_VENDOR_DLKMIMAGE := true` → the LineageOS kernel task installs
  every built `.ko` into `$(TARGET_OUT_VENDOR_DLKM)/lib/modules`, runs `depmod`
  against a `0.0` placeholder and writes `modules.load` from
  `BOARD_VENDOR_KERNEL_MODULES_LOAD` (= `modules.load`).
* `BOOT_KERNEL_MODULES` + `BOARD_VENDOR_RAMDISK_KERNEL_MODULES_LOAD`
  (= `modules.load.boot`) put the first-stage subset into the vendor ramdisk,
  which is where the stock vendor ramdisk keeps them too.

Both lists were derived from the stock lists crossed with what
`e5_rongyue_defconfig` actually builds:

| | stock | kept | dropped |
|---|---|---|---|
| vendor_dlkm | 120 + 73 built-only | **155** | — |
| first stage | 83 | **42** | 41 built-in (`=y`) |

`modules.load.boot` must only ever name modules the kernel really builds as
`=m`: the build task `find`s each name and hard-fails ("ERROR: … from
BOOT_KERNEL_MODULES was not found") if one is missing. If you change the
defconfig, regenerate both lists — `modules.load` tolerates absent entries
(`init` logs and continues), `modules.load.boot` does not.

---

## 6. Verification notes

Values below were read off the device (`adb root`) or parsed out of the stock
images; they are the reason the config looks the way it does.

**Boot image layout** — stock images parsed as `struct boot_img_hdr_v4`:

```
boot_a.img         kernel_size 0x2c97000   ramdisk_size 0        -> kernel only
init_boot_a.img    kernel_size 0           ramdisk_size 0x1bf526 -> generic ramdisk
vendor_boot_a.img  "VNDRBOOT" hdr v4, page 4096,
                   kernel_addr 0x8000, ramdisk_addr 0x05400000,
                   vendor_ramdisk_size 0x4ce9a61
dtb_a.img          all zeroes
dtbo_a.img         populated
```

That is a textbook GKI layout, hence
`BOARD_USES_GENERIC_KERNEL_IMAGE := true` + `BOARD_INIT_BOOT_IMAGE_PARTITION_SIZE`.
`ramdisk_addr == 0x05400000` is `BOARD_RAMDISK_OFFSET`; `kernel_addr == 0x8000`
is mkbootimg's default `--kernel_offset` with `BOARD_KERNEL_BASE := 0`.

**Vendor ramdisk** — decompressed the stock lz4 ramdisk and listed the cpio:

```
first_stage_ramdisk/fstab.ums9158_1h10
lib/modules/modules.load
lib/modules/modules.load.recovery
lib/modules/*.ko            (164 module files)
```

so `$(TARGET_COPY_OUT_VENDOR_RAMDISK)/first_stage_ramdisk/fstab.<hw>` and
`BOOT_KERNEL_MODULES` are exactly the right hooks.

**Stock first-stage fstab** (`/proc/mounts` + the ramdisk copy): `system`,
`system_ext`, `product`, `vendor`, `odm`, `vendor_dlkm`, `system_dlkm` are all
**erofs** and live in `super`; `/data` is f2fs with `reservedsize=128M,checkpoint=fs`;
the metadata partition is f2fs/ext4. `system_dlkm` is an empty 54 KiB
filesystem (108 × 512 B), so it is deliberately **not** part of the group this
tree builds. Its fstab line is commented out of our first-stage fstab to match.

**HALs** — `ps -Z` on the running stock system shows the vendor HAL services on
standard Treble domains: `hal_audio_default`, `hal_bluetooth_default`,
`hal_camera_default`, `hal_wifi_default`, `hal_sensors_default`,
`hal_graphics_composer_default`, `hal_bootctrl_default`, `hal_health_default`, …
which is why a LineageOS-built policy is close to usable. The exceptions are
listed in [§7](#7-known-issues--todo).

**Other** — `ro.hardware` / `ro.boot.hardware` = `ums9158_1h10` (this is what
init uses to pick `init.<hw>.rc` and `fstab.<hw>`, which is why the fstab file
and the init scripts are named after `ums9158_1h10`, not `e5`);
`ro.board.platform` = `ums9621`; the UDC is `musb-hdrc.1.auto`.

---

## 7. Known issues / TODO

1. **Vendor SELinux policy** (biggest risk). Unisoc's policy is not available as
   source, and the build regenerates `/vendor/etc/selinux/*` from
   `BOARD_VENDOR_SEPOLICY_DIRS`. The stock compiled policy cannot be reused
   (its platform hash will not match a LineageOS-built `/system`). The following
   Unisoc-only domains therefore do not exist in a LineageOS policy:

   ```
   hal_codec2_unisoc        hal_cplog_svcaidl_default   hal_enhanceaidl_default
   hal_logaidl_default      hal_networkaidl_default     hal_trustyclientaidl_default
   hal_oemlock_default      hal_broadcastradio_ext     charger_vendor
   tee                      watchdogd
   ```

   `androidboot.selinux=permissive` is set in `BOARD_KERNEL_CMDLINE` (stock is
   permissive too) so that everything that does not depend on a missing domain
   still comes up. Removing that flag is the last step of the port; add the
   domains under a `sepolicy/vendor/` directory and wire it up with
   `BOARD_VENDOR_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/vendor`.

2. **Unisoc framework extensions.** `system_ext/framework/{unisoc-framework,
   uni-telephony-common,unipnp-framework}.jar` and `system/framework/{unisoc-services,
   unipnp-services,unipnp-features,unisoc_ims_common}.jar` are extracted as
   blobs but are *not* registered as boot jars. Anything that loads them through
   the stock boot classpath (IMS, unipnp consumers) will fail with
   `ClassNotFoundException`. Registering them means adding
   `PRODUCT_BOOT_JARS += unisoc-framework unipnp-framework …` **and** checking
   they still resolve against the LineageOS `framework.jar` — they were built
   against the stock one.

3. **Camera / fingerprint.** The kernel has no source for the camera group or
   `aw322xx_charger` (see `artifacts_e5/driver_gap_2026-09-12.md`), and the
   Unisoc camera stack is a prebuilt blob stack (`/odm/lib64/libcam*.so`,
   `camera.ums9621.so`) driven by `sprd_camera.ko`. Expect camera and
   fingerprint work to be a separate follow-up.

4. **AVB.** `BOARD_AVB_ENABLE := true` with the AOSP test key and `--flags 3`
   (hashtree + verification disabled). If the Unisoc bootloader rejects a
   test-key vbmeta, set `BOARD_AVB_ENABLE := false` and flash the partitions
   individually — the device boots fine without AVB.

5. **Tethering / hotspot limits.** The stock ROM caps the number of concurrent
   hotspots and pins the 5 GHz channel / hotspot IP (the two `荣悦E5…模块` zips in
   the workspace patch this). Those live in `/vendor` and `/odm` blobs, so they
   carry over unchanged; re-apply the modules after any vendor blob refresh.

6. **`system_dlkm`.** Not built and not in the super group. If a later
   LineageOS change starts expecting it, add
   `BOARD_USES_SYSTEM_DLKMIMAGE := true`, add `system_dlkm` to
   `BOARD_UMS9621_DYNAMIC_PARTITIONS_PARTITION_LIST` and restore its fstab line.

7. **recovery / vendor_boot.** Lineage recovery rides in the vendor ramdisk
   (`BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT := true`), same as the
   existing TWRP port for this device.

---

## 8. License

Apache-2.0, except for `configs/vintf/*` and `proprietary-files.txt` which
describe proprietary Unisoc components and are covered by their own terms.
