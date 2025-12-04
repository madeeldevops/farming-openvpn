# farming-openvpn

A fully automated **OpenVPN LXC Farming System** that lets you deploy multiple OpenVPN servers inside LXC containers, auto-map ports, auto-generate `.ovpn` files, and sync logs every minute via cron — with a single command.

---

## 🚀 Overview

`farming-openvpn` turns a single Ubuntu host into a **cluster of OpenVPN servers**, each running inside its own LXC container.

The system handles:

- Provisioning LXC containers
- Installing OpenVPN inside each container
- Sharing a master `/etc/openvpn` config across all containers
- Mapping unique host ports → container ports via LXD proxy devices
- Updating a client `.ovpn` file with the correct public IP + all mapped ports
- Pulling OpenVPN status logs from each container
- Setting up a cron job to sync logs every minute

---

## ✨ Features

- 🧩 Create *N* OpenVPN LXC containers in one go
- 🔁 Consistent key + config replication (`/etc/openvpn`) across all instances
- 🌐 Dynamic host → LXC port mapping (1194, 1195, 1196, …)
- 🧾 Auto-generation and modification of the client `.ovpn` file
- 📡 Per-container log syncing (`openvpn-status.log`) to the host
- ⏱️ Cron-based log sync every 1 minute
- 🧱 Modular bash scripts:
  - `master.sh` – main orchestrator
  - `lxc-provision.sh` – create containers + install OpenVPN
  - `lxc-port-map.sh` – map host ports to LXC OpenVPN ports (if used)
  - `ovpn-log-sync.sh` – sync logs to host
  - `install-cron.sh` – install cron job for log sync
  - `openvpn-install-v3.sh` – OpenVPN install script used inside containers

---

## 📦 Repository Structure

```text
farming-openvpn/
│
├── master.sh               # Main orchestrator (run this)
├── lxc-provision.sh        # Creates LXCs + installs OpenVPN
├── lxc-port-map.sh         # (Optional) Host-to-LXC port mapping
├── ovpn-log-sync.sh        # Sync OpenVPN logs for monitoring
├── install-cron.sh         # Adds cron job for log syncing
├── openvpn-install-v3.sh   # Script pushed into LXC to install OpenVPN
└── README.md               # This file
```

---

## 🧱 Architecture

```text
            Ubuntu Host (Public IP)
                   │
           ┌───────┴────────┬────────────┐
           │                │            │
     ┌──────────┐      ┌──────────┐   ┌──────────┐
     │  ovpn1   │      │  ovpn2   │   │  ovpn3   │
     │10.x.x.11 │      │10.x.x.12 │   │10.x.x.13 │
     │1194->UDP │      │1195->UDP │   │1196->UDP │
     └──────────┘      └──────────┘   └──────────┘
           │                │            │
   Auto-generated client config (client.ovpn)
           │
   remote <PUBLIC_IP> 1194
   remote <PUBLIC_IP> 1195
   remote <PUBLIC_IP> 1196
```

Each container runs its own OpenVPN server, and the generated client config includes multiple remote lines pointing to each mapped port on the host.

---

## ⚙️ Requirements

- Ubuntu 20.04+ / 22.04+ host
- LXD/LXC installed (snap recommended)
- User added to lxd group:

```bash
sudo usermod -aG lxd ubuntu
```

**Note:** Log out and log back in after running this.

---

## 🛠️ Installation & Usage

### 1️⃣ Clone & Run

Get started in a few commands:

```bash
# Clone the repo
git clone https://github.com/madeeldevops/farming-openvpn.git

# Move into the project directory
cd farming-openvpn

# Make all scripts executable
chmod +x *.sh

# Launch the main orchestrator
./master.sh
```

---

## 🔐 Security Recommendations

- Disable root and password-based SSH login on the host
- Use SSH keys and possibly VPN-based management
- Use `ufw` or another firewall on the host to restrict access
- Rotate client configs and keys regularly
- Give different `.ovpn` files to different users instead of sharing one file
- Limit who can access the LXD socket (`/var/snap/lxd/common/lxd/unix.socket`)

---

## 📝 FAQ

**Q: Can I deploy more than 3 containers?**
Yes. When running `master.sh` simply enter a higher number when asked, e.g., 10.

**Q: Does each container use a unique port?**
Yes. They are mapped sequentially (e.g. 1194, 1195, 1196, …) via LXD proxy devices.

**Q: Why multiple remote lines in the .ovpn file?**
The OpenVPN client tries them in order. If one server is down, it can connect to another.

**Q: Why LXC instead of Docker?**
LXC gives you a more "full system" environment with low overhead and better isolation than just processes in containers, which is handy for VPN stacks.

---

## 🙌 Contributions

Contributions are welcome!
- Open an issue if you find bugs or have feature requests
- Submit a PR for improvements, fixes, or new features

---

## 📄 License


---

## 👤 Author

[@madeeldevops](https://github.com/madeeldevops)