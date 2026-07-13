# MikroTik-NV2-Point-to-Point-Link
Transparent Layer-2 NV2 wireless bridge between two MikroTik RBwAPG-5HacT2HnD units running RouterOS 7.12.1.  Designed for a fixed outdoor PTP link (e.g. hilltop access point to base station), with an optional local 2.4 GHz Wi-Fi AP on the remote unit for on-site clients.
# SITE1 — MikroTik NV2 Point-to-Point Link

Transparent Layer-2 NV2 wireless bridge between two **MikroTik RBwAPG-5HacT2HnD** units running **RouterOS 7.12.1**.

Designed for a fixed outdoor PTP link (e.g. hilltop access point to base station), with an optional local 2.4 GHz Wi-Fi AP on the remote unit for on-site clients.

---

## Hardware

| Role | Device | Radio used |
|---|---|---|
| PARENT | MikroTik RBwAPG-5HacT2HnD | wlan2 (5 GHz) |
| REMOTE | MikroTik RBwAPG-5HacT2HnD | wlan2 (5 GHz PTP) + wlan1 (2.4 GHz AP) |

---

## Features

- **Transparent Layer-2 bridge** — behaves like a long Ethernet cable between the two sites; no routing, no NAT
- **5 GHz NV2 PTP link** at 5660 MHz, 20 MHz channel width, dynamic distance
- **NV2 security** with pre-shared key (replace before deployment)
- **Conservative auto-recovery** — restarts wlan2 after ~10 minutes without a peer, without rebooting or changing RF parameters
- **Nightly backup** — exports config to flash every night (PARENT at 03:15, REMOTE at 03:30)
- **Manual scripts** — `SITE1-Link-Status` and `SITE1-Radio-Recovery` available from the terminal
- **Minimal attack surface** — telnet, FTP, API, UPnP, SOCKS, bandwidth server and RoMON all disabled
- **Fail-safe management IPs** — PARENT `192.168.88.1`, REMOTE `192.168.88.2` (always reachable even if DHCP fails)
- Local 2.4 GHz WPA2 AP on REMOTE (SSID: `SITE1`)

---

## Files

| File | Role |
|---|---|
| `SITE1-PARENT-FINAL-v3.rsc` | NV2 master (base/router side) |
| `SITE1-REMOTE-FINAL-v3.rsc` | NV2 station + local 2.4 GHz AP (hilltop/remote side) |

---

## Quick Start

### Before you begin

1. Start from a **clean factory reset** (`/system reset-configuration no-defaults=yes`)
2. Connect via **MAC WinBox** or direct Ethernet — do not use IP during import
3. **Change the NV2 pre-shared key** and Wi-Fi password before deployment (search for `SITE1-Wifi-Pass-2026!` in both files)

### Import

```
# On PARENT unit:
/import SITE1-PARENT-FINAL-v3.rsc

# On REMOTE unit:
/import SITE1-REMOTE-FINAL-v3.rsc
```

### Verify

```
# Check NV2 link status (run on either unit):
/system script run SITE1-Link-Status

# Check wlan2 registration table:
/interface wireless registration-table print
```

---

## Network Layout

```
[Router/Modem]
      |
   ether1
      |
 [PARENT unit]          5 GHz NV2 @ 5660 MHz
  wlan2 (master) ========================== wlan2 (station) [REMOTE unit]
                                                    |
                                                 ether1
                                                    |
                                            [Remote switch/LAN]
                                                    |
                                          wlan1 (2.4 GHz AP)
                                          SSID: SITE1
```

Both units are **transparent bridges** — all devices on either side share the same Layer-2 broadcast domain.

---

## Management

| Unit | Fail-safe IP | DHCP address |
|---|---|---|
| PARENT | `192.168.88.1` | from upstream DHCP |
| REMOTE | `192.168.88.2` | from upstream DHCP |

Access via WinBox, WebFig (`http://<ip>`), or SSH.

---

## RF Parameters

| Parameter | Value |
|---|---|
| Protocol | NV2 (MikroTik proprietary TDMA) |
| Frequency | 5660 MHz |
| Channel width | 20 MHz |
| Band | 5 GHz a/n/ac |
| Distance | Dynamic |
| Security | NV2 pre-shared key |
| Installation | Outdoor |

> **Note:** NV2 is a MikroTik proprietary protocol. Both units must be MikroTik hardware. Standard 802.11 clients cannot associate to an NV2 link.

---

## Customisation

| What to change | Where |
|---|---|
| NV2 pre-shared key | `nv2-preshared-key` in both files |
| Local Wi-Fi password | `wpa2-pre-shared-key` in REMOTE file |
| Local Wi-Fi SSID | `ssid="SITE1"` in REMOTE file |
| Frequency | `frequency=5660` in both files |
| Channel width | `channel-width=20mhz` in both files |
| Timezone | `time-zone-name` in both files |

---

## Auto-Recovery Logic

Every 2 minutes a scheduler checks whether `wlan2` has a registered NV2 peer. After **5 consecutive failures** (~10 minutes), it disables and re-enables `wlan2`. It intentionally:

- Does **not** reboot the router
- Does **not** change frequency, power or protocol
- Resets the fail counter immediately when the peer returns

This avoids destructive oscillation if the remote unit is intentionally powered off.

---

## License

MIT — free to use, modify and share. Attribution appreciated.

---

## Contributing

Pull requests welcome. Please test on physical hardware before submitting.
