#!/bin/bash
set -e

CURRENT_USER=$(id -un)

echo "=== Frame Dongle Recovery v2 ==="
echo

# --- Precheck: password on current user ---
if ! passwd -S "$CURRENT_USER" 2>/dev/null | grep -q " P "; then
    echo "WARNING: No password is set on user '$CURRENT_USER'."
    echo "Some recovery steps (pkexec) may fail or prompt for a password."
    echo "It is recommended to set a password with: passwd"
    echo
    if command -v zenity >/dev/null 2>&1; then
        zenity --warning --text="No password set on $CURRENT_USER.\nRecovery may prompt for password." --title="Frame Dongle Recovery" 2>/dev/null || true
    fi
fi

# 1. Force wpa_supplicant backend
echo "[1/5] Forcing wpa_supplicant backend..."
/usr/bin/steamos-polkit-helpers/steamos-wifi-set-backend-privileged write_config wpa_supplicant || true

# 2. Find the dongle connection
echo "[2/5] Finding dongle connection..."
DONGLE_CONN=$(nmcli -t -f NAME,802-11-wireless.hidden,connection.autoconnect-priority connection show | \
  awk -F: '$2=="yes" || $3>=900 {print $1; exit}')

if [ -z "$DONGLE_CONN" ]; then
    DONGLE_CONN=$(nmcli -t -f NAME connection show | grep -iE "frame|dongle" | head -n1)
fi

if [ -n "$DONGLE_CONN" ]; then
    echo "  Found: $DONGLE_CONN"
    nmcli connection modify "$DONGLE_CONN" connection.autoconnect-priority 100 2>/dev/null || true
    nmcli connection modify "$DONGLE_CONN" ipv4.never-default yes 2>/dev/null || true
else
    echo "  Could not auto-detect dongle connection."
fi

# 3. Clean duplicate home Wi-Fi profiles
echo "[3/5] Cleaning duplicate home Wi-Fi profiles..."
HOME_SSID=$(nmcli -t -f 802-11-wireless.ssid connection show | grep -v "^$" | sort | uniq -c | sort -nr | head -n1 | awk -F: '{print $2}')

if [ -n "$HOME_SSID" ]; then
    echo "  Primary home SSID: $HOME_SSID"
    MAIN_HOME=$(nmcli -t -f NAME,802-11-wireless.ssid connection show | grep ":$HOME_SSID$" | head -n1 | cut -d: -f1)
    if [ -n "$MAIN_HOME" ]; then
        nmcli connection modify "$MAIN_HOME" connection.autoconnect-priority 600 2>/dev/null || true
    fi

    DUPLICATES=$(nmcli -t -f NAME,802-11-wireless.ssid connection show | grep ":$HOME_SSID$" | tail -n +2 | cut -d: -f1)
    for dup in $DUPLICATES; do
        echo "  Removing duplicate: $dup"
        nmcli connection delete "$dup" 2>/dev/null || true
    done
fi

# 4. Restart NetworkManager
echo "[4/5] Restarting NetworkManager..."
systemctl restart NetworkManager
sleep 3

echo "[5/5] Done."
echo
echo "Now unplug the wireless dongle, wait 3 seconds, then plug it back in."
