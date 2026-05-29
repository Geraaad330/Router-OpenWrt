#!/bin/sh
# /etc/monit.d/notify.sh (Version for GL-MT6000 Router - OpenWrt)

# --- URL CONFIGURATION ---
GOTIFY_URL="https://domena.gotify/message?token=..."
DISCORD_URL="https://discordapp.com/api/webhooks/..."

# --- GL-MT6000 TEMPERATURE HANDLING ---
# Pobieranie i konwertowanie temperatury z sensora MediaTek w OpenWrt
if [ "$MONIT_SERVICE" = "router_temp" ]; then
    if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
        TEMP_RAW=$(cat /sys/class/thermal/thermal_zone0/temp)
        CURRENT_TEMP=$(awk "BEGIN {print $TEMP_RAW/1000}")
        MONIT_DESCRIPTION="CPU temperature is ${CURRENT_TEMP}°C and matches resource limit [75.0°C]"
    fi
fi

# --- EMOJI MAPPING ---
# 1. Najpierw dopasowujemy ikonki po nazwach specyficznych usług routera
case "$MONIT_SERVICE" in
    "adguardhome")  EMOJI="🛡️  DNS" ;;
    "dnsmasq")      EMOJI="📇  DHCP" ;;
    "INTERNET_WAN") EMOJI="🌐  WAN" ;;
    *)              EMOJI="" ;;
esac

# 2. Jeśli usługa to zasób systemowy (CPU/RAM), dopasowujemy ikonkę po opisie błędu
if [ -z "$EMOJI" ]; then
    case "$MONIT_DESCRIPTION" in
        *"temperature"*) EMOJI="🌡️  TEMP" ;;
        *"cpu usage"*)    EMOJI="⚙️  CPU" ;;
        *"mem usage"*)    EMOJI="📟  RAM" ;;
        *"loadavg"*)      EMOJI="📈  LOAD" ;;
        *"space usage"*)  EMOJI="💽  DYSK" ;;
        *)                EMOJI="⚠️  ALERT" ;;
    esac
fi

# --- SEND TO GOTIFY ---
if [ ! -z "$GOTIFY_URL" ]; then
    curl -s -X POST "$GOTIFY_URL" \
        -F "title=📡 Router Flint 2 | $EMOJI" \
        -F "message=$MONIT_DESCRIPTION"
fi

# --- SEND TO DISCORD ---
if [ ! -z "$DISCORD_URL" ]; then
    curl -s -H "Content-Type: application/json" -X POST \
        -d "{\"content\":\"📡 Router Flint 2 | $EMOJI: $MONIT_DESCRIPTION\"}" \
        "$DISCORD_URL"
fi
