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

The router utilizes **Monit** to continuously monitor system resources and critical services. Upon detecting an anomaly (e.g., high CPU usage, overheating, or service failure), it executes a custom notification script (`notify.sh`) to send alerts.

The configuration for Monit is stored in `/etc/monit.d/`:

```conf
# =========================================================================
# OPENWRT ROUTER MONITORING (SCRIPT NOTIFICATIONS)
# =========================================================================

# Swap is not monitored as it is not used on routers
check system $HOST
    if cpu usage > 80% for 2 cycles then exec "/etc/monit.d/notify.sh"
    if memory usage > 80% then exec "/etc/monit.d/notify.sh"
    if loadavg (1min) > 4.0 then exec "/etc/monit.d/notify.sh"

# --- DISK MONITORING ---
check filesystem root_partition with path /
    if space usage > 85% then exec "/etc/monit.d/notify.sh"

# --- TEMPERATURE MONITORING ---
check program router_temp with path "/bin/sh -c 'if [ $(cat /sys/class/thermal/thermal_zone0/temp) -gt 75000 ]; then exit 1; else exit 0; fi'"
    if status > 0 for 2 cycles then exec "/etc/monit.d/notify.sh"

# --- DNS MONITORING (ADGUARD HOME) ---
check process adguardhome matching "AdGuardHome"
    if failed host 127.0.0.1 port 53 type udp then exec "/etc/monit.d/notify.sh"

# --- DHCP MONITORING (DNSMASQ) ---
check process dnsmasq matching "dnsmasq"
    if failed host 127.0.0.1 port 67 type udp then exec "/etc/monit.d/notify.sh"

# --- INTERNET MONITORING (WAN) ---
check host INTERNET_WAN with address 1.1.1.1
    if failed ping count 3 with timeout 5 seconds for 2 cycles then exec "/etc/monit.d/notify.sh"
