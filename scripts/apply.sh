#!/system/bin/sh
# shark8-gsi-logspam-cosmetics: apply on the device (run as root, adb root or su).
# Installs the KernelSU module and persists the IMS log-level prop.
set -e

DIR=$(cd "$(dirname "$0")" && pwd)
MODDIR=/data/adb/modules
MOD=$MODDIR/selinux_cosmetics

echo "[*] installing module files"
mkdir -p "$MOD"
cp -f "$DIR/../module/module.prop"     "$MOD/module.prop"
cp -f "$DIR/../module/sepolicy.rule"   "$MOD/sepolicy.rule"
chmod 644 "$MOD/module.prop" "$MOD/sepolicy.rule"

echo "[*] persist IMS provisioning log tag at level E (silence)"
setprop persist.log.tag.ImsProvisioningController E
echo "     current: $(getprop persist.log.tag.ImsProvisioningController)"

echo "[+] done. sepolicy.rule is applied at next boot: adb reboot"