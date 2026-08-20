#!/bin/bash
# ==========================================
# WireGuard Installer - by znandev
# ==========================================
set -e

GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

clear

echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[44;1;39m       INSTALL WIREGUARD VPN       \E[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""

# ================= CHECK ROOT =================
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ Please run as root!${NC}"
   exit 1
fi

echo -e "${YELLOW}[*] Memulai instalasi WireGuard...${NC}"

# ================= INSTALL DEPENDENCIES =================
export DEBIAN_FRONTEND=noninteractive
apt-get update -y >/dev/null 2>&1 || true

apt-get install -y --no-install-recommends \
    wireguard \
    wireguard-tools \
    qrencode \
    resolvconf >/dev/null 2>&1 || true

# ================= DIRECTORY & KEYS =================
mkdir -p /etc/wireguard
cd /etc/wireguard || exit

if [[ ! -f private.key ]]; then
    privkey=$(wg genkey)
    pubkey=$(echo "$privkey" | wg pubkey)
    echo "$privkey" > private.key
    echo "$pubkey" > public.key
    chmod 600 private.key
    chmod 644 public.key
else
    privkey=$(cat private.key)
    pubkey=$(cat public.key)
fi

# ================= NETWORK INTERFACE =================
interface=$(ip route | grep default | awk '{print $5}' | head -n1)

if [[ -z "$interface" ]]; then
    echo -e "${RED}[ERROR] Failed to detect network interface!${NC}"
    exit 1
fi

# ================= WG0 CONFIG =================
cat > wg0.conf <<EOF
[Interface]
Address = 10.66.66.1/24
ListenPort = 51820
PrivateKey = $privkey
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o $interface -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o $interface -j MASQUERADE
SaveConfig = true
EOF

chmod 600 wg0.conf

# ================= IP FORWARDING =================
cat > /etc/sysctl.d/30-wg.conf <<EOF
net.ipv4.ip_forward=1
EOF

sysctl --system >/dev/null 2>&1

# ================= TESTING CONFIG =================
wg-quick strip wg0 >/dev/null 2>&1 || {
    echo -e "${RED}[ERROR] Invalid WireGuard configuration!${NC}"
    exit 1
}

# ================= SERVICE START =================
systemctl daemon-reload
systemctl enable wg-quick@wg0 >/dev/null 2>&1
systemctl restart wg-quick@wg0

sleep 2

if ! systemctl is-active --quiet wg-quick@wg0; then
    echo -e "${RED}[ERROR] WireGuard failed to start!${NC}"
    journalctl -u wg-quick@wg0 -n 20 --no-pager
    exit 1
fi

# ================= LOG INSTALL =================
touch /root/log-install.txt
grep -q "WireGuard" /root/log-install.txt || \
echo "WireGuard        : 51820" >> /root/log-install.txt

clear

# ================= SUMMARY =================
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[44;1;39m     WIREGUARD INSTALLED SUCCESS   \E[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e " Status        : ${GREEN}RUNNING (ONLINE)${NC}"
echo -e " Port          : 51820"
echo -e " Interface     : wg0 (via $interface)"
echo -e " Config Path   : /etc/wireguard/wg0.conf"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""

sleep 3
exit 0
