#!/bin/bash
# lxc-provision

#LXC_COUNT=${LXC_COUNT:-3}

START=1
END=$LXC_COUNT

echo
echo "[INFO] Launching $LXC_COUNT LXC containers..."

#launches no of lxcs stated
for i in $(seq $START $END); do
  lxc launch ubuntu:noble ovpn$i
done

echo "[INFO] Pushing OpenVPN installation script in all lxcs"
#push openvpn installation script in all lxcs
for i in $(seq $START $END); do
  lxc file push openvpn-install-v4.sh ovpn$i/root/
done

echo "[INFO] Installing OpenVPN script in all lxcs"
#install openvpn in all lxcs
for i in $(seq $START $END); do
  echo "->[INFO] Installing OpenVPN inside ovpn$i..."
  lxc exec ovpn$i -- bash -c "cd /root && apt update -y && printf '\n\n\n' | ./openvpn-install-v4.sh"
done

echo "[INFO] Pulls the /etc/openvpn/ directory from the frist lxc for consistent keys"
lxc file pull -r ovpn$START/etc/openvpn/ ${HOME}/


echo "[INFO] Pushes this directory to all lxcs for consistency"
for i in $(seq $START $END); do
  lxc file push -r ${HOME}/openvpn/ ovpn$i/etc/
done

echo "[INFO] Replacing the first line in server.conf with LXC IP"

for c in $(lxc list -c n --format csv | grep ovpn); do
    container_ip=$(lxc exec "$c" -- sh -c "ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'")
    # Replace the first line in server.conf with correct IP
    lxc exec "$c" -- bash -c "
        sed -i '1s|^local .*|local $container_ip|' /etc/openvpn/server/server.conf"
    echo "-->[INFO] Replacing ovpn$START ip in $c with local ip $container_ip in /etc/openvpn/server/server.conf"

done

echo "-->[INFO] Restart the openvpn server and check its status (sanity check) and running"
for i in $(seq $START $END); do
  echo "--->[INFO] LXC ovpn$i"
  lxc exec ovpn$i -- systemctl restart openvpn-server@server
  lxc exec ovpn$i -- systemctl status openvpn-server@server --no-pager
done

# Port binding
echo "->[INFO] Port binding"

# Injection from master script
#HOST_IP=$(curl -4 -s ifconfig.me)
START_PORT=1194

i=0
for c in $(lxc list -c n --format csv | grep ovpn); do
    container_ip=$(lxc exec "$c" -- sh -c "ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'")
    listen_port=$((START_PORT + i))
    device_name="vpn$listen_port"

    echo "Adding proxy for $c --> $container_ip:$START_PORT (listen $HOST_IP:$listen_port)"
    lxc config device add "$c" "$device_name" proxy \
        listen=udp:$HOST_IP:$listen_port \
        connect=udp:$container_ip:1194

    i=$((i+1))
done

# Pulls the client file from the first lxc to the host
echo "[INFO] Pulls the client file from the first lxc to the host with name $CLIENT_NAME in ${HOME}/openvpn/client/"
lxc file pull ovpn$START/root/client.ovpn ${HOME}/openvpn/client/$CLIENT_NAME.ovpn


# Editing the ports in the client file
CLIENT_FILE="${HOME}/openvpn/client/$CLIENT_NAME.ovpn"
echo "->[INFO] Auto-detecting mapped ports from LXC proxy devices..."

# echo "Host IP is ${HOST_IP}"
for c in $(lxc list -c n --format csv | grep ovpn); do
    # echo "Value of C is $c"
    # c=$(echo "$c" | tr -d '\r' | xargs)
    listen_port=$(lxc config device show "$c" | awk '/listen:/ {split($2,a,":"); print a[3]}')
    # echo "Listen port is $listen_port"
    if [[ ! -z "$listen_port" ]]; then
        REMOTE_BLOCK+="remote ${HOST_IP} ${listen_port}\n"
        echo "-->[INFO] Found mapped port $listen_port for container $c"
        # echo "Remote block is : $REMOTE_BLOCK"

    fi
done
# echo "Host IP is ${HOST_IP}"

echo "[INFO] Injecting remote entries into $CLIENT_FILE ..."
sed -i "1a $REMOTE_BLOCK" "$CLIENT_FILE"
echo "[INFO] Client file updated successfully!"
sed -n '1,20p' "$CLIENT_FILE"




# # make directory for monitoring

# if [ ! -d "/home/ubuntu/monitoring" ]; then
#   echo "/home/ubuntu/monitoring already exists — skipping create."
#   mkdir /home/ubuntu/monitoring/
# else
#   echo "Creating /home/ubuntu/monitoring directory..."
#   mkdir /home/ubuntu/monitoring
# fi

#docker compose installation

# sudo apt update
# sudo apt install apt-transport-https ca-certificates curl software-properties-common
# curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
# echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
# sudo apt update
# sudo apt install docker-ce docker-compose-plugin -y
# docker compose version
# sudo systemctl status docker
# sudo usermod -aG docker ${USER}