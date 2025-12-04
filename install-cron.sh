# install-cron.sh
# Update the crontab
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CRON_LINE="* * * * * LXC_COUNT=${LXC_COUNT} ${SCRIPT_DIR}/ovpn-log-sync.sh >> ${HOME}/cron.log 2>&1"
echo "[INFO] Old cronjob file"
crontab -l 2>/dev/null; echo "$CRON_LINE" | crontab -
echo "[INFO] Updated crontab:"
crontab -l