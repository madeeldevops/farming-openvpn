#!/bin/bash
# MASTER.SH

trap 'echo ""; echo "⚠️  Script interrupted by user (Ctrl+C). Exiting cleanly..."; exit 130' INT


# Ask user how many LXCs to provision
read -p "How many LXC servers do you want? (default: 3)" LXC_COUNT

# If user presses ENTER → use default value
LXC_COUNT=${LXC_COUNT:-3}

# Detect public IP automatically (you can override)
DEFAULT_IP=$(curl -4 -s ifconfig.me)
read -p "Enter Public IP (default: $DEFAULT_IP): " HOST_IP
HOST_IP=${HOST_IP:-$DEFAULT_IP}

# Ask for OpenVPN client name
read -p "Enter the name for first VPN client (default: client1): " CLIENT_NAME
CLIENT_NAME=${CLIENT_NAME:-client1}

echo "[INFO] LXC_COUNT=$LXC_COUNT | HOST_IP=$HOST_IP | CLIENT_NAME=$CLIENT_NAME"

# Export so other scripts can use it
export LXC_COUNT
export HOST_IP
export CLIENT_NAME

echo
echo "======================================="
echo " STEP 1 — Provision LXC Containers"
echo "======================================="
HOST_IP=$HOST_IP CLIENT_NAME=$CLIENT_NAME ./lxc-provision.sh

# echo
# echo "======================================="
# echo " STEP 2 — Map Host Ports to LXCs"
# echo "======================================="
# HOST_IP=$HOST_IP ./lxc-port-map.sh

echo
echo "======================================="
echo " STEP 2 — Sync Logs for Monitoring"
echo "======================================="
LXC_COUNT=$LXC_COUNT ./ovpn-log-sync.sh

echo
echo "======================================="
echo " STEP 3 — Adding Cron Job for Log Sync"
echo "======================================="
LXC_COUNT=$LXC_COUNT ./install-cron.sh

echo
echo "======================================="
echo " STEP 4 — Update FVM Backend with Stats"
echo "======================================="
LXC_COUNT=$LXC_COUNT ./update-server-fvm.sh uuid-uid-uuid-uuid-uuiduuid
