#!/bin/bash
# ==========================================
# ZNAND UDP ZIVPN INSTALLER - by znandev
# ==========================================
set -e

clear

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[44;1;39m       INSTALL UDP ZIVPN           \E[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""

# ==============================
# CHECK ROOT
# ==============================
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ Please run as root!${NC}"
   exit 1
fi

# ==============================
# UPDATE SYSTEM (Aman & Non-Interactive)
# ==============================
echo -e "${YELLOW}[*] Updating system packages...${NC}"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y >/dev/null 2>&1 || true

# ==============================
# INSTALL DEPENDENCIES
# ==============================
echo -e "${YELLOW}[*] Installing dependencies...${NC}"
apt-get install -y --no-install-recommends \
wget \
curl \
openssl \
net-tools \
ufw \
iptables >/dev/null 2>&1 || true

# ==============================
# STOP OLD SERVICE
# ==============================
systemctl stop zivpn >/dev/null 2>&1 || true

# ==============================
# DOWNLOAD BINARY (Versi 1.4.9)
# ==============================
echo -e "${YELLOW}[*] Downloading ZiVPN binary...${NC}"
wget -q -O /usr/local/bin/zivpn \
https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64

chmod +x /usr/local/bin/zivpn

if [[ ! -f /usr/local/bin/zivpn ]]; then
    echo -e "${RED}❌ Failed downloading binary ZiVPN!${NC}"
    exit 1
fi

# ==============================
# CREATE DIRECTORY & CONFIG
# ==============================
echo -e "${YELLOW}[*] Configuring directory and users...${NC}"
mkdir -p /etc/zivpn

if [[ ! -f /etc/zivpn/users.db ]]; then
    echo "testuser" > /etc/zivpn/users.db
fi

# ==============================
# GENERATE SSL CERTIFICATE
# ==============================
if [[ ! -f /etc/zivpn/zivpn.crt || ! -f /etc/zivpn/zivpn.key ]]; then
    echo -e "${YELLOW}[*] Generating SSL certificate...${NC}"
    openssl req -new -newkey rsa:4096 \
    -days 3650 \
    -nodes \
    -x509 \
    -subj "/C=ID/ST=Jakarta/L=Jakarta/O=ZNAND/OU=UDP/CN=zivpn" \
    -keyout /etc/zivpn/zivpn.key \
    -out /etc/zivpn/zivpn.crt >/dev/null 2>&1
fi

# ==============================
# GENERATE CONFIG JSON
# ==============================
echo -e "${YELLOW}[*] Generating JSON configuration...${NC}"
USERS=$(awk '{print "\"" $1 "\""}' /etc/zivpn/users.db | paste -sd "," -)

cat > /etc/zivpn/config.json <<EOF
{
  "listen": ":5667",
  "cert": "/etc/zivpn/zivpn.crt",
  "key": "/etc/zivpn/zivpn.key",
  "obfs": "zivpn",
  "auth": {
    "mode": "passwords",
    "config": [ $USERS ]
  }
}
EOF

# ==============================
# SYSTEM OPTIMIZATION (UDP Buffer)
# ==============================
echo -e "${YELLOW}[*] Optimizing system UDP buffer...${NC}"
sysctl -w net.core.rmem_max=16777216 >/dev/null 2>&1
sysctl -w net.core.wmem_max=16777216 >/dev/null 2>&1

grep -q "net.core.rmem_max" /etc/sysctl.conf || echo "net.core.rmem_max=16777216" >> /etc/sysctl.conf
grep -q "net.core.wmem_max" /etc/sysctl.conf || echo "net.core.wmem_max=16777216" >> /etc/sysctl.conf

sysctl -p >/dev/null 2>&1 || true

# ==============================
# CREATE SYSTEMD SERVICE
# ==============================
echo -e "${YELLOW}[*] Creating systemd service...${NC}"
cat > /etc/systemd/system/zivpn.service <<EOF
[Unit]
Description=ZiVPN UDP Server - by znandev
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/zivpn
ExecStart=/usr/local/bin/zivpn server -c /etc/zivpn/config.json
Restart=always
RestartSec=3s
Environment=ZIVPN_LOG_LEVEL=info

[Install]
WantedBy=multi-user.target
EOF

# ==============================
# IPTABLES RULES
# ==============================
echo -e "${YELLOW}[*] Setting up iptables rules...${NC}"
iptables -t nat -C PREROUTING -p udp --dport 6000:19999 -j REDIRECT --to-ports 5667 2>/dev/null || \
iptables -t nat -A PREROUTING -p udp --dport 6000:19999 -j REDIRECT --to-ports 5667 || true

# Save iptables secara aman
DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent >/dev/null 2>&1 || true
netfilter-persistent save >/dev/null 2>&1 || true

# ==============================
# ENABLE & START SERVICE
# ==============================
echo -e "${YELLOW}[*] Starting ZiVPN service...${NC}"
systemctl daemon-reload
systemctl enable zivpn >/dev/null 2>&1
systemctl restart zivpn

sleep 2

if systemctl is-active --quiet zivpn; then
    STATUS="${GREEN}RUNNING (ONLINE)${NC}"
else
    STATUS="${RED}FAILED (OFFLINE)${NC}"
fi

clear

# ==============================
# OUTPUT / SUMMARY
# ==============================
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[44;1;39m       ZIVPN INSTALLED SUCCESS     \E[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e " Service Status : $STATUS"
echo -e " UDP Port       : 5667 (Redirect 6000-19999)"
echo -e " Config Path    : /etc/zivpn/config.json"
echo -e " Users DB       : /etc/zivpn/users.db"
echo -e " Default User   : testuser"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""

sleep 3
exit 0
