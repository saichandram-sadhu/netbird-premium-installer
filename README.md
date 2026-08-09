# NetBird Premium VPN - 1-Click Installer 🚀

A highly customized, fully automated 1-click deployment script for [NetBird VPN](https://netbird.io/). This script deploys the complete NetBird backend, a **Basic-Auth protected Management Dashboard**, and a **custom-designed Premium Animated Download Page** with zero hassle.

## Features ✨
* **1-Click Deployment:** Automatically configures Docker, Traefik, NetBird Server, and the Download Page.
* **Dynamic Domain Configuration:** Prompts for your domain and configures SSL automatically via Let's Encrypt.
* **Premium Download Page:** A beautifully designed, animated, bento-grid style download page that auto-detects the user's OS and provides 1-click setup instructions.
* **Dashboard Security:** The main NetBird dashboard is locked behind Basic Authentication (HTTP auth) to prevent unauthorized public access, while the `/download` page remains public.
* **Zero Port Conflicts:** Automatically routes everything cleanly through Traefik using standard ports `80` and `443`.

## Prerequisites 🛠
Before running the script, ensure you have a fresh Linux server (Ubuntu/Debian recommended) with:
1. **Docker & Docker Compose** installed.
2. A **Domain Name** pointed to your server's IP address (A Record).
3. Ports `80` and `443` open in your firewall.

## Installation 📦

Run the following commands on your new server to deploy the VPN:

```bash
# 1. Clone the repository
git clone https://github.com/saichandram-sadhu/netbird-premium-installer.git

# 2. Enter the directory
cd netbird-premium-installer

# 3. Make the script executable
chmod +x netbird-premium-installer.sh

# 4. Run the installer
sudo ./netbird-premium-installer.sh
```

## Setup Process
During installation, the script will prompt you for:
* **Domain Name** (e.g., `vpn.yourdomain.com`)
* **Let's Encrypt Email** (For SSL certificates)
* **Dashboard Admin Username** (To secure the management UI)
* **Dashboard Admin Password** (Securely hashed locally)

## Accessing Your Services
Once the deployment finishes:
* **Dashboard:** `https://your-domain.com` (Requires the Username & Password you set during install)
* **Download Page:** `https://your-domain.com/download` (Publicly accessible for your users to download clients)

---
*Powered by NetBird & Custom Animated UI*
