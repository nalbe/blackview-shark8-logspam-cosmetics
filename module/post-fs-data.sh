#!/system/bin/sh
# Persistently apply classic-format sepolicy rules via ksud, because
# KernelSU 0.9.4 cannot parse magisk colon-format sepolicy.rule and its
# boot-time load path is unreliable. Rules live in sepolicy.rule.
MODDIR=${0%/*}
RULES="$MODDIR/sepolicy.rule"

[ -f "$RULES" ] || exit 0

# KernelSU sepolicy binary
KSUD=/data/adb/ksud
[ -x "$KSUD" ] || exit 0

# Apply rules (classic space-separated format, logged one line per rule).
"$KSUD" sepolicy apply "$RULES" >/dev/null 2>&1

# 0.9.4 has no reset_avc_cache; stale deny cache keeps old denials firing
# even after rules land. Toggle enforcing to flush AVC cache.
if [ -w /sys/fs/selinux/enforce ]; then
    echo 0 > /sys/fs/selinux/enforce 2>/dev/null
    echo 1 > /sys/fs/selinux/enforce 2>/dev/null
fi

exit 0
