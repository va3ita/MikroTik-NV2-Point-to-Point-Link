# SITE1-REMOTE-FINAL-v3.rsc
# MikroTik RBwAPG-5HacT2HnD - RouterOS 7.12.1
# Full configuration from a clean no-defaults reset.
# Role: transparent Layer-2 NV2 station + local 2.4 GHz AP.
# Management: DHCP + 192.168.88.2/24
#
# IMPORTANT:
# - Import while connected by MAC WinBox or local Ethernet.
# - This file does not reset the router.
# - NV2 frequency: 5660 MHz, channel width: 20 MHz.
# - Local AP SSID: SITE1.

# ---------- Identity and clock ----------
/system identity set name="SITE1-REMOTE"
/system clock set time-zone-autodetect=no time-zone-name=Europe/Gibraltar
/system note set show-at-login=yes note="SITE1 REMOTE | NV2 station + local AP | management 192.168.88.2"

# ---------- Interface lists ----------
/interface list
add name=MGMT comment="Interfaces permitted for local management"

/interface list member
add interface=ether1 list=MGMT

# ---------- Transparent bridge ----------
/interface bridge
add name=bridge-ptp protocol-mode=rstp fast-forward=yes igmp-snooping=no \
    comment="Transparent Layer-2 PTP bridge"

/interface bridge settings
set allow-fast-path=yes use-ip-firewall=no use-ip-firewall-for-vlan=no

/interface bridge port
add bridge=bridge-ptp interface=ether1 path-cost=10 comment="Remote switch/LAN"
add bridge=bridge-ptp interface=wlan2 path-cost=20 comment="5 GHz NV2 PTP"
add bridge=bridge-ptp interface=wlan1 path-cost=30 comment="Local 2.4 GHz AP"

/interface list member
add interface=bridge-ptp list=MGMT

# ---------- Local 2.4 GHz WPA2 profile ----------
/interface wireless security-profiles
add name=SITE1-LOCAL-SEC mode=dynamic-keys authentication-types=wpa2-psk \
    unicast-ciphers=aes-ccm group-ciphers=aes-ccm \
    wpa2-pre-shared-key="SITE1-Wifi-Pass-2026!" \
    supplicant-identity=MikroTik

# ---------- Local 2.4 GHz AP ----------
/interface wireless
set [find default-name=wlan1] \
    disabled=no \
    mode=ap-bridge \
    band=2ghz-g/n \
    channel-width=20mhz \
    frequency=auto \
    ssid="SITE1" \
    security-profile=SITE1-LOCAL-SEC \
    country=no_country_set \
    installation=indoor \
    frequency-mode=manual-txpower \
    wireless-protocol=802.11 \
    adaptive-noise-immunity=ap-and-client-mode \
    wmm-support=enabled \
    compression=no \
    hide-ssid=no \
    default-authentication=yes \
    default-forwarding=yes \
    comment="Local SITE1 Wi-Fi AP"

# ---------- 5 GHz NV2 station bridge ----------
/interface wireless
set [find default-name=wlan2] \
    disabled=no \
    mode=station-bridge \
    band=5ghz-a/n/ac \
    channel-width=20mhz \
    frequency=5660 \
    scan-list=5660 \
    ssid="SITE1-PTP" \
    radio-name="SITE1-REMOTE" \
    wireless-protocol=nv2 \
    nv2-security=enabled \
    nv2-preshared-key="SITE1-Wifi-Pass-2026!" \
    distance=dynamic \
    adaptive-noise-immunity=ap-and-client-mode \
    installation=outdoor \
    country=no_country_set \
    frequency-mode=manual-txpower \
    tx-power-mode=default \
    compression=no \
    default-authentication=yes \
    default-forwarding=yes \
    comment="SITE1 5 GHz NV2 station bridge"

# ---------- Management addressing ----------
/ip address
add address=192.168.88.2/24 interface=bridge-ptp \
    comment="Fail-safe static management IP"

/ip dhcp-client
add interface=bridge-ptp disabled=no add-default-route=yes \
    default-route-distance=10 use-peer-dns=yes use-peer-ntp=yes \
    comment="Dynamic production-LAN management address"

# ---------- DNS and NTP ----------
/ip dns
set allow-remote-requests=no

/system ntp client
set enabled=yes mode=unicast

/system ntp client servers
add address=time.cloudflare.com comment="Primary NTP"
add address=time.google.com comment="Secondary NTP"

# ---------- IP management services ----------
/ip service
set telnet disabled=yes
set ftp disabled=yes
set www disabled=no
set www-ssl disabled=no
set ssh disabled=no
set winbox disabled=no
set api disabled=yes
set api-ssl disabled=yes

# ---------- MAC management and discovery ----------
/tool mac-server
set allowed-interface-list=MGMT

/tool mac-server mac-winbox
set allowed-interface-list=MGMT

/ip neighbor discovery-settings
set discover-interface-list=MGMT

# ---------- Disable unused auxiliary services ----------
/tool bandwidth-server set enabled=no
/tool romon set enabled=no
/ip socks set enabled=no
/ip proxy set enabled=no
/ip upnp set enabled=no

# ---------- Watchdog ----------
/system watchdog
set watchdog-timer=yes automatic-supout=yes watch-address=none

# ---------- Logging ----------
/system logging
add topics=wireless,info action=memory
add topics=wireless,warning action=memory
add topics=interface,warning action=memory

# ---------- Manual link-status report ----------
/system script
add name=SITE1-Link-Status policy=read,test source={
    :put "================================================";
    :put " SITE1 REMOTE - LINK STATUS";
    :put "================================================";
    :put ("Date/time: " . [/system clock get date] . " " . [/system clock get time]);
    :put ("Uptime: " . [/system resource get uptime]);
    :put ("CPU load: " . [/system resource get cpu-load] . "%");
    :put ("Free memory: " . [/system resource get free-memory]);
    :put "---------------- PTP RADIO ---------------------";
    /interface wireless monitor wlan2 once;
    :put "---------------- PTP PEER ----------------------";
    /interface wireless registration-table print detail where interface=wlan2;
    :put "---------------- LOCAL CLIENTS -----------------";
    /interface wireless registration-table print detail where interface=wlan1;
    :put "---------------- DHCP --------------------------";
    /ip dhcp-client print detail where interface=bridge-ptp;
    :put "================================================";
}

# ---------- Manual radio recovery ----------
/system script
add name=SITE1-Radio-Recovery policy=read,write,test source={
    :log warning "SITE1: manual wlan2 recovery started";
    /interface wireless disable wlan2;
    :delay 10s;
    /interface wireless enable wlan2;
    :delay 20s;
    :log warning "SITE1: manual wlan2 recovery completed";
    /interface wireless monitor wlan2 once;
}

# ---------- Automatic local backup ----------
/system script
add name=SITE1-Nightly-Backup policy=read,write,policy,test,sensitive source={
    :log info "SITE1: nightly configuration backup started";
    /system backup save name="SITE1-REMOTE-AUTO" dont-encrypt=yes;
    /export show-sensitive file="SITE1-REMOTE-AUTO";
    :log info "SITE1: nightly configuration backup completed";
}

/system scheduler
add name=SITE1-Nightly-Backup start-time=03:30:00 interval=1d \
    on-event=SITE1-Nightly-Backup policy=read,write,policy,test,sensitive


# ---------- Conservative automatic NV2 recovery ----------
# Every 2 minutes the device checks whether wlan2 has a registered NV2 peer.
# After five consecutive failed checks (about 10 minutes), it restarts wlan2.
# It deliberately does NOT reboot the router and does NOT change frequency,
# power, channel width or protocol. This avoids destructive oscillation when
# the peer is intentionally powered off or the path is temporarily blocked.
/system script
add name=SITE1-Auto-Recovery policy=read,write,test source={
    :global SITE1FailCount;
    :if ([:typeof $SITE1FailCount] = "nothing") do={ :set SITE1FailCount 0; }

    :local peerCount [/interface wireless registration-table print count-only where interface=wlan2];

    :if ($peerCount > 0) do={
        :if ($SITE1FailCount > 0) do={
            :log info ("SITE1: NV2 peer restored after " . $SITE1FailCount . " failed checks");
        }
        :set SITE1FailCount 0;
    } else={
        :set SITE1FailCount ($SITE1FailCount + 1);
        :log warning ("SITE1: NV2 peer absent, failed check " . $SITE1FailCount . "/5");

        :if ($SITE1FailCount >= 5) do={
            :log error "SITE1: restarting wlan2 after about 10 minutes without peer";
            /interface wireless disable wlan2;
            :delay 10s;
            /interface wireless enable wlan2;
            :set SITE1FailCount 0;
        }
    }
}

/system scheduler
add name=SITE1-Auto-Recovery start-time=startup interval=2m \
    on-event=SITE1-Auto-Recovery policy=read,write,test

# ---------- Final note ----------
:log warning "SITE1-REMOTE configuration loaded. Verify wlan2 association, DHCP and local SSID."
