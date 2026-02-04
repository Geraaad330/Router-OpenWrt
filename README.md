# 🏠 Konfiguracja Sieci Domowej (OpenWrt / GL.iNet Flint 2)

Repozytorium zawiera pliki konfiguracyjne dla routera **GL.iNet Flint 2 (GL-MT6000)**. Projekt realizuje architekturę bezpiecznej sieci domowej z podziałem na VLAN-y (izolacja IoT/Gości) oraz zdalnym dostępem przez Mesh VPN (NetBird).

## 🛠 Sprzęt

| Urządzenie | Model | Rola |
| :--- | :--- | :--- |
| **Router** | GL.iNet Flint 2 (MT-6000) | Brama sieciowa, Firewall, AdGuard Home, VPN Gateway |
| **Switch** | Wbudowany (DSA) | Zarządzanie ruchem przewodowym (VLAN 50, 60) |

## 🌐 Topologia Sieci (VLAN & DSA)

Sieć została skonfigurowana w oparciu o **Distributed Switch Architecture (DSA)**, co pozwala na niezależne przypisywanie portów fizycznych do wirtualnych sieci LAN.

| VLAN ID | Nazwa Strefy | Typ / Porty | Opis |
| :--- | :--- | :--- | :--- |
| **50** | `lan` (Trusted) | **LAN 1, 2, 3** | Główna sieć domowa. Pełny dostęp do internetu i wszystkich urządzeń. |
| **60** | `lan60` (IoT/Lab) | **LAN 4, 5** | Odizolowana sieć przewodowa. Dostęp do Internetu, ale brak dostępu do sieci głównej (LAN). |
| **70** | `guest_wifi` | **Virtual (WiFi)** | Sieć wyłącznie dla gości/WiFi. Całkowita izolacja od reszty sieci domowej. |
| **-** | `netbird` | **Interfejs wt0** | Wirtualny interfejs dla tunelu VPN (WireGuard). |

## 🔒 Firewall i Bezpieczeństwo

Konfiguracja opiera się na zasadzie **"Default Reject"** – domyślnie ruch jest blokowany, chyba że istnieje reguła zezwalająca.

### 1. Strefa Gości (`guest_wifi` - VLAN 70)
* **Izolacja:** Całkowita blokada dostępu do Routera (`Input: REJECT`) oraz innych sieci lokalnych (`Forward: REJECT`).
* **Usługi:** Jawnie odblokowano tylko niezbędne porty UDP, aby sieć działała:
  * Port **67** (DHCP) – przydzielanie adresów IP.
  * Port **53** (DNS) – rozwiązywanie nazw (obsługiwane przez AdGuard Home).
* **Internet:** Ruch wychodzący do WAN jest dozwolony.

### 2. Strefa IoT / Lab (`lan60` - VLAN 60)
* **Izolacja:** Podobnie jak w strefie gości, blokada dostępu do Routera (SSH/Panel WWW) oraz sieci głównej.
* **Przeznaczenie:** Bezpieczne środowisko dla urządzeń IoT, drukarek przewodowych lub testowych serwerów.

### 3. VPN Zone (`netbirdzone`)
Strefa zaufana dla zdalnego dostępu administracyjnego.
* **Dostęp administracyjny:** `Input: ACCEPT` – użytkownik połączony przez VPN ma dostęp do panelu routera, SSH i AdGuarda.
* **Routing:** Włączona **Maskarada (NAT)**, aby urządzenia w LAN poprawnie odpowiadały na zapytania z tunelu VPN.
* **Fix:** Włączony `mtu_fix` zapobiegający problemom z fragmentacją pakietów w tunelu.

## 🚦 Reguły Ruchu (Traffic Rules)

Zdefiniowano wyjątki od polityki izolacji ("Dziury w murze"):

1.  **Dostęp do Drukarki:**
    * Umożliwia druk z sieci głównej (`lan`) na drukarkę w sieci izolowanej (`lan60`).
    * Umożliwia druk z sieci gości (`guest_wifi`) na drukarkę w sieci izolowanej (`lan60`).
    * *Security Note:* Dostęp jest ograniczony wyłącznie do konkretnego adresu IP drukarki.

2.  **NetBird VPN Routing:**
    * **VPN -> LAN:** Dostęp do zasobów domowych z zewnątrz.
    * **VPN -> WAN:** Funkcja "Exit Node" (bezpieczne wyjście na świat przez domowe IP).
    * **LAN -> VPN:** Możliwość inicjowania połączeń do zdalnych peerów z sieci domowej.

## 📂 Pliki konfiguracyjne

W tym repozytorium znajdują się ocenzurowane (sanitized) wersje plików:
* `/etc/config/network` - Konfiguracja interfejsów, mostków i przypisanie portów.
* `/etc/config/firewall` - Definicje stref, reguł forwarding i traffic rules.

---
*Uwaga: Wszelkie wrażliwe dane, takie jak publiczne adresy IP, adresy MAC, klucze prywatne oraz hasła zostały usunięte z plików konfiguracyjnych dla bezpieczeństwa.*
