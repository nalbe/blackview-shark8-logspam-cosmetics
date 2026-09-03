#!/system/bin/sh
# shark8-gsi-logspam-cosmetics: apply on the device (run as root, adb root or su).
# Installs the KernelSU module and persists the IMS log-level prop.
set -e

DIR=$(cd "$(dirname "$0")" && pwd)
MODDIR=/data/adb/modules
MOD=$MODDIR/selinux_cosmetics

echo "[*] installing module files"
mkdir -p "$MOD"
cp -f "$DIR/../module/module.prop"      "$MOD/module.prop"
cp -f "$DIR/../module/sepolicy.rule"    "$MOD/sepolicy.rule"
cp -f "$DIR/../module/post-fs-data.sh"  "$MOD/post-fs-data.sh"
chmod 644 "$MOD/module.prop" "$MOD/sepolicy.rule"
chmod 755 "$MOD/post-fs-data.sh"

echo "[*] persist IMS provisioning log tag at level E (silence)"
setprop persist.log.tag.ImsProvisioningController E
echo "     current: $(getprop persist.log.tag.ImsProvisioningController)"

echo "[*] apply sepolicy rules immediately (classic format)"
if [ -x /data/adb/ksud ]; then
    /data/adb/ksud sepolicy apply "$MOD/sepolicy.rule"
    # 0.9.4 lacks reset_avc_cache; flush stale deny cache via enabling toggle
    if [ -w /sys/fs/selinux/enforce ]; then
        echo 0 > /sys/fs/selinux/enforce 2>/dev/null
        echo 1 > /sys/fs/selinux/enforce 2>/dev/null
    fi
fi

echo "[+] done. immediate apply + boot persist via post-fs-data.sh"