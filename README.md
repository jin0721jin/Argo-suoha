🌐 Languages:  
[English](README.md) | [中文说明](README.zh_CN.md)

# Argo-suoha

> TT Cloudflare Tunnel one-click suoha script — No public IP required | No port forwarding | Argo Tunnel | Supports VMess/VLESS | Automatic domain obfuscation selection

# 🚀 Argo-suoha

> **A new-generation lightweight penetration tool based on Cloudflare Tunnel**
>
> No public IP | No port forwarding | Extreme stealth | Built for NAT VPS

![License](https://img.shields.io/badge/License-MIT-green.svg)
![Language](https://img.shields.io/badge/Language-Bash-blue.svg)
![Platform](https://img.shields.io/badge/Platform-Linux-lightgrey.svg)
![Powered By](https://img.shields.io/badge/Powered%20By-Cloudflare%20Tunnel-orange)

---

## 📖 Project Introduction
**Argo-suoha** is a fully automated one-click deployment script based on Cloudflare Tunnel (Argo) technology.

It is designed to solve the problem where machines without public IP, strict firewalls, or NAT environments (such as HAX, IPv6-only VPS) cannot expose services to the public. By establishing an outbound tunnel, it enables secure public access to local services without any port mapping.

This project is refactored & optimized by **tt** , integrating the latest Xray core, fixing logic flaws in the original version, and providing more stable connections and improved domain camouflage.

## ✨ Core Features

* **⚡️Zero-barrier deployment**：No public IP, no complex firewall configuration — one command to “suoha”.
* **🛡️Advanced camouflage**：Automatically configures domain-based routing (SNI/Host separation) to resist active probing.
* **🛠Multi-protocol support**：Freely choose **VMess** 或 **VLESS** according to your client needs.
* **🌍Cross-architecture compatibility**：Fully supports `x86_64` (AMD64), `arm64` (Mac M1/VPS), `armv7` ,and more.
* **🚀Smart optimization**：Built-in Argo tunnel optimization to automatically find the best Cloudflare access point.
* 
## 📌 Feature Highlights
* **🚀Suoha Mode (Temporary Tunnel)**
No domain required
The temporary tunnel becomes invalid after reboot; script must be re-run

* **🚀Service Mode (Persistent Tunnel)**
Requires a Cloudflare-managed domain bound to Argo Tunnel
Service remains active after reboot

Both modes support:
Automatic CF Argo node optimization
VMess and VLESS
No public IP, no port forwarding, fully stealth

---
## ⭐ Give it a Star
💖 If you find this project useful, please give me a star so I know how many people benefited from it.


## ⚠️ Disclaimer

This disclaimer applies to the "Argo-suoha" project on GitHub (hereinafter referred to as "this project").

### Purpose
The Project is designed and developed solely for educational, research, 和 security testing purposes.
It aims to provide security researchers, academics, and technical enthusiasts with a tool to explore and practice network communication technologies.

### Legality
When downloading and using the Project, users must comply with applicable local laws and regulations.
Users are responsible for ensuring that their actions comply with the legal framework and rules of their jurisdiction.

### Liability
1. As the **secondary developer** (hereinafter “the Author”), I **tt** emphasize that the Project is for legal, ethical, 和 educational usage only.
2. The Author does not endorse, support, or encourage any form of illegal use. Any illegal or unethical use is strongly condemned.
3.The Author is not liable for any illegal activities conducted using this Project. All consequences are the sole responsibility of the user.
4. The Author is not responsible for any direct or indirect damage caused by using this Project.
5. To avoid legal risks or unintended consequences, users should delete the Project code with24 小时之内 of use.
Commercial use is prohibited. All code, data, 和 images retain their respective copyrights; attribution is required when redistributing.

By using this Project, users acknowledge and agree to all terms of this disclaimer.
If you do not agree, discontinue using the Project immediately.

The Author reserves the right to update this disclaimer at any time without notice.
The latest version will always be published on the Project’s GitHub page.

## 💻 One-Click Installation (Quick Start)

Run the following command in your VPS terminal (supports Debian / Ubuntu / CentOS / Alpine):

**GitHub 原始链接**
```bash
bash <(curl -sL https://raw.githubusercontent.com/jin0721jin/Argo-suoha/refs/heads/main/suoha.sh | tr -d '\r')
```
**📌Select mode based on the menu**

1 Suoha mode (No Cloudflare domain; invalid after reboot)
2 Install service (Requires Cloudflare domain; persists after reboot)
3 Uninstall service 
4 Clear cache 
5 Manage service
0.Exit script

**✨✨ Once Service Mode is installed, run`suoha`to view links, start/stop/restart/uninstall services, 和 manage the Tunnel.**


