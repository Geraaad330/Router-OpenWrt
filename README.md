# 🏠 Home Network Configuration (OpenWrt / GL.iNet Flint 2)

This repository contains configuration files for the **GL.iNet Flint 2 (GL-MT6000)** router. The project implements a secure home network architecture divided into VLANs (IoT/Guest isolation) with remote access via Mesh VPN (NetBird).

## 🛠 Hardware

| Device | Model | Role |
| :--- | :--- | :--- |
| **Router** | GL.iNet Flint 2 (MT-6000) | Network Gateway, Firewall, AdGuard Home, VPN Gateway |
| **Switch** | Built-in (DSA) | Wired traffic management (VLAN 50, 60) |

## 🌐 Network Topology (VLAN & DSA)

The network is configured based on **Distributed Switch Architecture (DSA)**, allowing independent physical port assignment to virtual LANs.

| VLAN ID | Zone Name | Type / Ports | Description |
| :--- | :--- | :--- | :--- |
| **50** | `lan` (Trusted) | **LAN 1, 2, 3** | Main home network. Full access to the Internet and all devices. |
| **60** | `lan60` (IoT/Lab) | **LAN 4, 5** | Isolated wired network. Internet access allowed, but no access to the main network (LAN). |
| **70** | `guest_wifi` | **Virtual (WiFi)** | Guest/WiFi network only. Total isolation from the rest of the home network. |
| **-** | `netbird` | **Interface wt0** | Virtual interface for the VPN tunnel (WireGuard). |

## 🔒 Firewall and Security

The configuration is based on a **"Default Reject"** policy – traffic is blocked by default unless an explicit allow rule exists.

### 1. Guest Zone (`guest_wifi` - VLAN 70)
* **Isolation:** Complete block on accessing the Router (`Input: REJECT`) and other local networks (`Forward: REJECT`).
* **Services:** Only essential UDP ports are explicitly unblocked for network operation:
  * Port **67** (DHCP) – IP address allocation.
  * Port **53** (DNS) – Name resolution (handled by AdGuard Home).
* **Internet:** Outbound traffic to WAN is allowed.

### 2. IoT / Lab Zone (`lan60` - VLAN 60)
* **Isolation:** Similar to the guest zone, access to the Router (SSH/Web Panel) and main network is blocked.
* **Purpose:** A secure environment for IoT devices, wired printers, or test servers.

### 3. VPN Zone (`netbirdzone`)
Trusted zone for remote administrative access.
* **Admin Access:** `Input: ACCEPT` – users connected via VPN have access to the router panel, SSH, and AdGuard.
* **Routing:** **Masquerading (NAT)** enabled so LAN devices correctly reply to queries from the VPN tunnel.
* **Fix:** `mtu_fix` enabled to prevent packet fragmentation issues in the tunnel.

## 🚦 Traffic Rules

Exceptions to the isolation policy ("Holes in the wall") have been defined:

**Printer Access:**
* Allows printing from the main network (`lan`) to the printer in the isolated network (`lan60`).
* Allows printing from the guest network (`guest_wifi`) to the printer in the isolated network (`lan60`).
> **Security Note:** Access is strictly restricted to the printer's specific IP address.

**NetBird VPN Routing:**
* **VPN -> LAN:** Access to home resources from the outside.
* **VPN -> WAN:** "Exit Node" function (secure outbound Internet access via the home IP).
* **LAN -> VPN:** Ability to initiate connections to remote peers from the home network.

## 📂 Configuration Files

This repository contains sanitized versions of the following files:
* `/etc/config/network` - Interface, bridge, and port assignment configuration.
* `/etc/config/firewall` - Zone definitions, forwarding, and traffic rules.

---

## 🔔 Monitoring (Monit)

The router utilizes **Monit** to continuously monitor system resources and critical services. Upon detecting an anomaly (e.g., high CPU usage, overheating, or service failure), it executes a custom notification script to send alerts.

* 📄 **[View the Monit configuration file](monit.d/monit_config)** (Defines thresholds for CPU, RAM, Disk, and Services).
* 📜 **[View the notification script (notify.sh)](monit.d/notify.sh)** (Handles sending webhooks to Gotify/Discord).
check host INTERNET_WAN with address 1.1.1.1
    if failed ping count 3 with timeout 5 seconds for 2 cycles then exec "/etc/monit.d/notify.sh"
