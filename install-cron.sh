#!/bin/bash
# install-cron.sh
# Update the crontab

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default LXC count
LXC_COUNT=${LXC_COUNT:-10}


# Cron job lines
CRON1="* * * * * LXC_COUNT=${LXC_COUNT} ${SCRIPT_DIR}/ovpn-log-sync.sh >> ${HOME}/cron-ovpn-logsync.log 2>&1"
CRON2="* * * * * LXC_COUNT=${LXC_COUNT} ${SCRIPT_DIR}/update-server-fvm.sh UUID >> ${HOME}/cron-ovpn-pushstats.log 2>&1"

# Create a temp crontab file
TMP_CRON=$(mktemp)

# Load existing cron entries (if any)
crontab -l 2>/dev/null > "$TMP_CRON"

# Add your entries (avoiding duplicates)
grep -qxF "$CRON1" "$TMP_CRON" || echo "$CRON1" >> "$TMP_CRON"
grep -qxF "$CRON2" "$TMP_CRON" || echo "$CRON2" >> "$TMP_CRON"

# Install updated cron
crontab "$TMP_CRON"

# Cleanup
rm "$TMP_CRON"

echo "[INFO] Cron jobs installed:"
crontab -l
