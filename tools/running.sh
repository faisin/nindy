#!/bin/bash
# ==========================================
# Script Running Status - by znandev
# ==========================================

red='\e[1;31m'
green='\e[0;32m'
yellow='\e[1;33m'
blue='\e[1;34m'
cyan='\e[1;36m'
NC='\e[0m'

# Cek Status Service
# Xray
if systemctl is-active --quiet xray; then
    xray_status="${green}ONLINE${NC}"
else
    xray_status="${red}OFFLINE${NC}"
fi

# Nginx
if systemctl is-active --quiet nginx; then
    nginx_status="${green}ONLINE${NC}"
else
    nginx_status="${red}OFFLINE${NC}"
fi

# Dropbear
if systemctl is-active --quiet dropbear; then
    dropbear_status="${green}ONLINE${NC}"
else
    dropbear_status="${red}OFFLINE${NC}"
fi

# Wireguard
if systemctl is-active --quiet wg-quick@wg0; then
    wg_status="${green}ONLINE${NC}"
else
    wg_status="${red}OFFLINE${NC}"
fi

# UDP Custom
if systemctl is-active --quiet udp-custom; then
    udp_custom_status="${green}ONLINE${NC}"
else
    udp_custom_status="${red}OFFLINE${NC}"
fi

# UDP Zivpn / Zivpn
if systemctl is-active --quiet zivpn || systemctl is-active --quiet udp-zivpn; then
    udp_zivpn_status="${green}ONLINE${NC}"
else
    udp_zivpn_status="${red}OFFLINE${NC}"
fi

# SSH WS (dropbearws / sshws)
if systemctl is-active --quiet dropbearws || systemctl is-active --quiet sshws; then
    sshws_status="${green}ONLINE${NC}"
else
    sshws_status="${red}OFFLINE${NC}"
fi

# WSS (stunnelws)
if systemctl is-active --quiet stunnelws; then
    wss_status="${green}ONLINE${NC}"
else
    wss_status="${red}OFFLINE${NC}"
fi

echo -e " XRAY       : $xray_status    NGINX       : $nginx_status"
echo -e " DROPBEAR   : $dropbear_status    WIREGUARD   : $wg_status"
echo -e " UDP CUSTOM : $udp_custom_status    UDP ZIVPN   : $udp_zivpn_status"
echo -e " SSH WS     : $sshws_status    WSS         : $wss_status"
