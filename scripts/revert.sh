#!/system/bin/sh
# shark8-gsi-logspam-cosmetics: full revert (run as root).
set -e

MODDIR=/data/adb/modules
MOD=$MODDIR/selinux_cosmetics

if [ -d "$MOD" ]; then
  rm -rf "$MOD"
  echo "[*] module $MOD removed"
else
  echo "[*] module not present, nothing to remove"
fi

setprop persist.log.tag.ImsProvisioningController ""
echo "[*] IMS log tag reset to default: $(getprop persist.log.tag.ImsProvisioningController)"

echo "[+] done. reboot to drop the patched policy: adb reboot"