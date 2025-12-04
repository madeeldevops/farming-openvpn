#!/bin/bash
# update-server-fvm.sh

# Load .env file if exists
if [[ -f .env ]]; then
  export $(grep -v '^#' .env | xargs)
fi

# Required UUID parameter
if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <uuid>"
  exit 1
fi

UUID=$1

# Default LXC count
LXC_COUNT=${LXC_COUNT:-3}

# Build dynamic log file list
LOG_FILES=()
for ((i=1; i<=LXC_COUNT; i++)); do
    LOG_FILES+=("${HOME}/ovpn$i-logs/openvpn-status.log")
done

# Values loaded from .env
API_URL=${API_URL}
AUTH_TOKEN=${AUTH_TOKEN}

# Count connected clients
CLIENT_COUNT=0
for LOG_FILE in "${LOG_FILES[@]}"; do
  if [[ -f "$LOG_FILE" ]]; then
    COUNT=$(grep -c '^CLIENT_LIST' "$LOG_FILE")
    CLIENT_COUNT=$((CLIENT_COUNT + COUNT))
  else
    echo "⚠️ Missing log: $LOG_FILE"
  fi
done

# Get interface with most traffic
TOP_IFACE=$(vnstat --json m | jq -r '.interfaces | max_by(.traffic.total.rx + .traffic.total.tx).name')

TOTAL_BYTES_IN=$(vnstat --json m -i "$TOP_IFACE" | jq '.interfaces[0].traffic.month[-1].rx / 1000 / 1000 / 1000 / 1000')
TOTAL_BYTES_OUT=$(vnstat --json m -i "$TOP_IFACE" | jq '.interfaces[0].traffic.month[-1].tx / 1000 / 1000 / 1000 / 1000')

RECV_SPEED="5"
SENT_SPEED="5"

RESPONSE=$(curl -s --location --request PUT "$API_URL" \
  --header "Authorization: token $AUTH_TOKEN" \
  --form "uid=$UUID" \
  --form "no_of_active_users=$CLIENT_COUNT" \
  --form "total_bytes_in=$TOTAL_BYTES_IN" \
  --form "total_bytes_out=$TOTAL_BYTES_OUT" \
  --form "recv_speed=$RECV_SPEED" \
  --form "sent_speed=$SENT_SPEED")

if echo "$RESPONSE" | grep -q '"status":"success"'; then
  echo "Updated server: $CLIENT_COUNT users"
else
  echo "API update failed: $RESPONSE"
fi
