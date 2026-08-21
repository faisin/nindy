#!/bin/bash
green='\033[0;32m'
red='\033[0;31m'
NC='\033[0m'

# XRAY
if systemctl is-active --quiet xray; then
    xray_status="${green}ONLINE${NC}"
else
    xray_status="${red}OFFLINE${NC}"
fi

# NGINX
if systemctl is-active --quiet nginx; then
    nginx_status="${green}ONLINE${NC}"
else
    nginx_status="${red}OFFLINE${NC}"
fi

# DROPBEAR
if systemctl is-active --quiet dropbear; then
    dropbear_status="${green}ONLINE${NC}"
else
    dropbear_status="${red}OFFLINE${NC}"
fi

# WIREGUARD
if systemctl is-active --quiet wg-quick@wg0 || systemctl is-active --quiet wireguard; then
    wg_status="${green}ONLINE${NC}"
else
    wg_status="${red}OFFLINE${NC}"
fi

# UDP Custom
status_udp=$(systemctl is-active udp-custom 2>/dev/null)
if [[ "$status_udp" == "active" || "$status_udp" == "activating" ]]; then
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
if systemctl is-active --quiet stunnelws || systemctl is-active --quiet wss; then
    wss_status="${green}ONLINE${NC}"
else
    wss_status="${red}OFFLINE${NC}"
fi

echo -e "               \033[1;36mSERVICE\033[0m"
echo -e " XRAY       : $xray_status    NGINX      : $nginx_status"
echo -e " DROPBEAR   : $dropbear_status    WIREGUARD  : $wg_status"
echo -e " UDP CUSTOM : $udp_custom_status    UDP ZIVPN  : $udp_zivpn_status"
echo -e " SSH WS     : $sshws_status    WSS        : $wss_status"
