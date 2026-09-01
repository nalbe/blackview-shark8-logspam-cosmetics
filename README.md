# blackview-shark8-logspam-cosmetics

One cosmetic patch for the Blackview Shark 8 running an Android 13 AOSP GSI
on the stock vendor image (KernelSU 0.9.4). Silences two recurring sources
of logspam caused by GSI/vendor mixing. Zero functional change, zero
permissive domains.

## What it fixes

### 1. ImsProvisioningController: getTechsFromCarrierConfig failed

Every ~30s `com.android.phone` logged W/D spam. Decompiled from the on-device
`TeleService.apk`: `isProvisioningRequired()` calls `getTechsFromCarrierConfig()`,
which looks up the carrier-config bundle `ims.mmtel_requires_provisioning_bundle`
and reads an int-array by capability key. The bundle exists but is empty
(`PersistableBundle[{}]`), so the array is null -> "getTechsFromCarrierConfig
failed" -> provisioning treated as not required.

That fallback is the correct behavior for an operator that does not gate IMS.
It is pure cosmetic noise, so instead of patching the dex we suppress the tag:

    persist.log.tag.ImsProvisioningController E

Takes effect immediately and survives reboot. Revert with an empty value.

### 2. SELinux avc find denials on nonexistent hwservices

`system_app` (telephony) probes vendor radio hwservices this chipset does not
provide (samsung_slsi/sprd/huawei/qti interfaces) and the fingerprint HAL
probes oppo/oplus hwservices; every miss lands on the
`default_android_hwservice` fallback context and floods auditd with
`{ find }` denials. Allowed via KernelSU `sepolicy.rule`:

    allow system_app default_android_hwservice:hwservice_manager find
    allow hal_fingerprint_oppo_compat default_android_hwservice:hwservice_manager find

### 3. Bonus: periodic process-getattr audit spam

The same mixing also makes `system_server`/`vold` audit `getattr` on foreign
domains (radio, gmscore_app, platform_app, device_as_webcam) every few
seconds. Same allow-rule treatment:

    allow system_server radio:process getattr
    allow system_server gmscore_app:process getattr
    allow system_server platform_app:process getattr
    allow system_server device_as_webcam:process getattr
    allow vold system_server:process getattr

## Layout

    module/
      module.prop       KernelSU module metadata
      sepolicy.rule     SELinux allow-rules, applied by ksud at boot
    scripts/
      apply.sh          device-side: copy module + persist IMS log tag
      revert.sh         device-side: remove module + reset IMS log tag
    shark8_gsi_logspam_cosmetics_v1.zip
                        ready-to-flash KernelSU module zip

## Install

Option A, KernelSU Manager: install the zip from the project root.

Option B, adb:

    adb push module/ /data/adb/modules/...              # or run apply.sh
    adb shell "sh /path/to/scripts/apply.sh"            # copies files + sets prop
    adb reboot

Option C, manual: put `module.prop` + `sepolicy.rule` into
`/data/adb/modules/selinux_cosmetics/` (as root), run
`setprop persist.log.tag.ImsProvisioningController E`, reboot.

## Revert

    adb shell "sh /path/to/scripts/revert.sh"
    adb reboot

or: delete `/data/adb/modules/selinux_cosmetics`, reset the prop, reboot.

The IMS log tag can be re-enabled at any time (no reboot needed):

    setprop persist.log.tag.ImsProvisioningController ""

## Verified on device (2026-09-02)

- Before: `avc: denied { find }` bursts at boot + fingerprint HAL retries
  every 10s; `ImsProvisioningController` W lines every ~30s.
- After reboot with the module: 0 `avc: denied` lines in logcat and dmesg
  (telephony confirmed running, 48 TeleService/CarrierConfig log lines),
  and 0 `ImsProvisioningController` lines in a 40s observation window.

Tooling note: baksmali shim lives at
`D:\System\Apps\android-sdk\tools\bin\baksmali.cmd` (on user PATH).