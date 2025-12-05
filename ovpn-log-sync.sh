#!/bin/bash
# ovpn-log-sync.sh

# Default to 3 if not exported
# If running manually (interactive terminal), ask user
# If running manually (interactive terminal), ask user
if [[ -t 0 && "$PS1" != "" ]]; then
    read -p "How many OVPN LXC servers do you want to sync? (default: 3) " LXC_COUNT
    LXC_COUNT=${LXC_COUNT:-3}
else
    LXC_COUNT=${LXC_COUNT:-3}
fi

echo "->[INFO] Syncing logs for $LXC_COUNT OpenVPN servers..."

for ((i=1; i<=LXC_COUNT; i++)); do
    INSTANCE="ovpn$i"
    DESTINATION_PATH="${HOME}/${INSTANCE}-logs/"
    LOG_FILE="${DESTINATION_PATH}openvpn-status.log"

    mkdir -p "$DESTINATION_PATH"

    # -----------------------------
    # Check if container is running
    # -----------------------------
    if ! lxc info "$INSTANCE" 2>/dev/null | grep -qi "running"; then
        echo "-->[INFO] $INSTANCE is STOPPED → clearing stale log"

        # If log file exists, empty it
        : > "$LOG_FILE"

        continue
    fi

    # -----------------------------
    # If container is running → pull log
    # -----------------------------
    echo "-->[INFO] Pulling logs from $INSTANCE..."

    lxc file pull "${INSTANCE}/var/log/openvpn/openvpn-status.log" "$DESTINATION_PATH" 2>/dev/null \
        && echo "✓ $INSTANCE logs updated" \
        || echo "⚠️ Failed to pull logs from $INSTANCE"
done

echo "[INFO] Log sync complete."
