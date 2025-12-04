#!/bin/bash
# CLEANUP OVPN + LXC (Non-interactive)
# cleanup.sh

echo "======================================="
echo "     CLEANUP: LXC OpenVPN Environment"
echo "======================================="
# If running manually (interactive terminal), ask user
if [[ -t 0 ]]; then
    read -p "How many OVPN LXC servers do you want to delete? (default: 3) " LXC_COUNT
    LXC_COUNT=${LXC_COUNT:-3}
else
    LXC_COUNT=${1:-3}
fi

echo "[INFO] Removing ovpn1 → ovpn$LXC_COUNT containers..."

# Stop & delete LXCs
for ((i=1; i<=LXC_COUNT; i++)); do
    NAME="ovpn$i"

    if lxc info "$NAME" &> /dev/null; then
        echo "Stopping $NAME ..."
        lxc stop "$NAME" --force

        echo "Deleting $NAME ..."
        lxc delete "$NAME"
    else
        echo "[SKIP] $NAME does not exist."
    fi
done

echo
echo "======================================="
echo "     Removing generated folder"
echo "======================================="

# Remove openvpn directory
if [ -d "${HOME}/openvpn" ]; then
    echo "Deleting ./openvpn/"
    rm -rf ${HOME}/openvpn
fi


echo
echo "======================================="
echo "     Removing log folders "
echo "======================================="
# Remove log folders
for ((i=1; i<=LXC_COUNT; i++)); do
    LOGDIR="${HOME}/ovpn$i-logs"
    if [ -d "$LOGDIR" ]; then
        echo "Deleting $LOGDIR/"
        rm -rf "$LOGDIR"
    fi
done

# Remove client.ovpn
[ -f "client.ovpn" ] && rm -f client.ovpn

echo
echo "======================================="
echo "   Cleanup Complete!"
echo "======================================="
