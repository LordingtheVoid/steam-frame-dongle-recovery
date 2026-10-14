# steam-frame-dongle-recovery
Recovery script + instructions for the official Steam Frame wireless dongle on Steam Machine SteamOS. Fixes iwd instability with the Frame's hidden 6 GHz AP.

## Important Note

**This is a workaround, not a stable solution.**  
It is intended for testers and tinkerers. Valve is expected to improve native dongle support in future SteamOS / SteamVR updates. Use at your own risk.

## Why This Happens

By default, SteamOS uses **iwd** as the Wi-Fi backend. The Steam Frame’s wireless dongle creates a hidden 6 GHz SAE access point. iwd currently has difficulty parsing this AP, resulting in repeated errors such as:

- `invalid HE capabilities`
- `CMD_TRIGGER_SCAN: Invalid argument`
- `hidden network's SSID was not revealed by scanning within timeout`

This causes NetworkManager to fail the connection, triggering the **“deactivated”** toast and constant reconnection attempts. The dongle connection is also created with a very high autoconnect priority, causing it to aggressively compete with your home Wi-Fi.

## What the Script Does

`fix-frame-dongle-v2.sh` performs the following:

- Forces NetworkManager to use the **`wpa_supplicant`** backend
- Lowers the dongle connection’s autoconnect priority
- Cleans up duplicate home Wi-Fi profiles
- Raises the priority of your main home connection
- Sets the dongle connection as `never-default`
- Restarts NetworkManager

## What to Expect & Prerequisites

### Set a Password (Recommended)

If your user has no password set, some steps may fail or repeatedly prompt. Set one with:

```bash
passwd
```

### Recommended Startup Sequence

For best results, follow this order exactly:

1. Power on the Steam Machine from a **completely powered off** state **without** the dongle plugged in.
2. Boot into **Desktop Mode**.
3. Launch **SteamVR** (Beta branch recommended) and wait until it is fully running.
4. Once SteamVR is running and the Steam Frame shows as connected, plug the dongle into the **front right USB port**.
5. On the desktop, right-click `fix-frame-dongle-v2.sh` → **Run in Konsole**.
6. Enter the password you set when prompted.
7. When instructed, unplug the dongle for **3 seconds**, then plug it back in.
8. Wait until the multilink indicator on the Frame turns **purple**.
9. Close the script window.
10. Test a game (e.g. Half-Life: Alyx).

## Usage

```bash
bash ~/fix-frame-dongle-v2.sh
```

## Limitations & Untested Configurations

This script has **not** been heavily tested on the following setups:

- Machines using **Ethernet only** (no Wi-Fi)
- Users who have **renamed the `deck` user**
- Non-SteamOS Linux distributions
- Multiple home Wi-Fi networks or complex routing setups
- Older or newer SteamOS / SteamVR versions outside the versions listed below

Feedback from users on these configurations is welcome.

## Current Known-Good Versions (October 2026)

| Device          | SteamOS                  | Kernel                                      | SteamVR     | Notes |
|-----------------|--------------------------|---------------------------------------------|-------------|-------|
| Steam Machine   | 3.9.2 (`20260925.101`)   | `7.2.7-valve1-1-neptune-72-gc8730d37f9c6`   | Beta `2.18.3` | Recommended |
| Steam Frame     | `20261007.6125817`       | -                                           | -           | - |

## Credits

This recovery method was developed with assistance from **Grok** and the **OpenClaw** agent.
