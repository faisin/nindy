#!/bin/bash
# ==========================================
# Xray Core + Nginx Reverse Proxy - by znandev
# ==========================================
set -e

GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

clear

echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[44;1;39m      INSTALL XRAY & NGINX         \E[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""

# ================= VALIDATION =================
if ! command -v nginx >/dev/null 2>&1; then
    echo -e "${RED}[ERROR] NGINX not installed!${NC}"
    echo -e "${YELLOW}Run install/nginx.sh first.${NC}"
    exit 1
fi

# Cek direktori konfigurasi secara fleksibel (mendukung nindy, AutoscriptXRAY, dll)
CONFIG_DIR="$(cd "$(dirname "$0")/.." && pwd)/config"
if [[ ! -d "$CONFIG_DIR" ]]; then
    CONFIG_DIR="$HOME/nindy/config"
fi
if [[ ! -d "$CONFIG_DIR" ]]; then
    CONFIG_DIR="$HOME/AutoscriptXRAY/config"
fi
if [[ ! -d "$CONFIG_DIR" ]]; then
    CONFIG_DIR="/etc/autoscriptvpn/config"
fi

if [[ ! -f "$CONFIG_DIR/xray.json" ]]; then
    echo -e "${RED}[ERROR] xray.json not found in $CONFIG_DIR!${NC}"
    exit 1
fi

if [[ ! -f "$CONFIG_DIR/xray.conf" ]]; then
    echo -e "${RED}[ERROR] xray.conf not found in $CONFIG_DIR!${NC}"
    exit 1
fi

# ================= DOMAIN CHECK =================
mkdir -p /etc/xray
if [[ -f /etc/xray/domain ]]; then
    domain=$(cat /etc/xray/domain)
elif [[ -f /root/domain ]]; then
    domain=$(cat /root/domain)
    echo "$domain" > /etc/xray/domain
else
    echo -e "${RED}[ERROR] File domain tidak ditemukan di /etc/xray/domain atau /root/domain!${NC}"
    exit 1
fi
echo "$domain" > /root/domain

# ================= INSTALL DEPENDENCY =================
echo -e "${YELLOW}[*] Installing dependencies...${NC}"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y >/dev/null 2>&1 || true

apt-get install -y --no-install-recommends \
curl wget socat cron jq unzip \
gnupg coreutils lsof qrencode \
ca-certificates >/dev/null 2>&1 || true

mkdir -p /etc/xray
mkdir -p /var/log/xray
mkdir -p /usr/local/bin

# ================= DOWNLOAD XRAY =================
echo -e "${YELLOW}[*] Downloading Xray Core...${NC}"
mkdir -p /tmp/xray

wget -qO /tmp/xray.zip \
"https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip" || { 
    echo -e "${RED}[ERROR] Failed to download Xray Core!${NC}" 
    exit 1 
}

unzip -o /tmp/xray.zip -d /tmp/xray >/dev/null 2>&1
install -m 755 /tmp/xray/xray /usr/local/bin/xray

rm -rf /tmp/xray
rm -f /tmp/xray.zip

# ================= ENABLE CRON =================
systemctl enable cron >/dev/null 2>&1
systemctl restart cron >/dev/null 2>&1

# ================= INSTALL ACME =================
if [ ! -f ~/.acme.sh/acme.sh ]; then
    echo -e "${YELLOW}[*] Menginstall acme.sh...${NC}"
    curl -s https://get.acme.sh | sh -s email=admin@$domain >/dev/null 2>&1 || true
fi

chmod +x ~/.acme.sh/acme.sh
~/.acme.sh/acme.sh --set-default-ca --server letsencrypt >/dev/null 2>&1 || true
~/.acme.sh/acme.sh --register-account -m admin@$domain >/dev/null 2>&1 || true

# ================= STOP PORT 80 =================
echo -e "${YELLOW}[*] Freeing Port 80 for SSL Issuance...${NC}"
systemctl stop nginx 2>/dev/null || true
systemctl stop apache2 2>/dev/null || true
fuser -k 80/tcp >/dev/null 2>&1 || true

# ================= ISSUE CERT =================
echo -e "${YELLOW}[*] Issuing SSL Certificate via Let's Encrypt...${NC}"
~/.acme.sh/acme.sh \
    --issue \
    -d "$domain" \
    --standalone \
    --keylength ec-256 \
    --force || {
        echo -e "${RED}[ERROR] Failed to issue SSL certificate!${NC}"
        exit 1
}

# ================= INSTALL CERT =================
~/.acme.sh/acme.sh \
    --install-cert \
    -d "$domain" \
    --ecc \
    --key-file /etc/xray/private.key \
    --fullchain-file /etc/xray/cert.crt || {
        echo -e "${RED}[ERROR] Failed to install certificate!${NC}"
        exit 1
}

# ================= PERMISSION =================
chmod 600 /etc/xray/private.key
chmod 644 /etc/xray/cert.crt

# ================= XRAY CONFIG =================
echo -e "${YELLOW}[*] Applying Xray & Nginx configurations...${NC}"
cp "$CONFIG_DIR/xray.json" /etc/xray/config.json
cp "$CONFIG_DIR/xray.conf" /etc/nginx/conf.d/xray.conf

chmod 644 /etc/xray/config.json
chmod 644 /etc/nginx/conf.d/xray.conf

# ================= XRAY SERVICE =================
cat > /etc/systemd/system/xray.service <<EOF
[Unit]
Description=Xray Service - by znandev
Documentation=https://github.com/xtls
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray -config /etc/xray/config.json
Restart=always
RestartSec=3s

[Install]
WantedBy=multi-user.target
EOF

# ================= TEST CONFIG =================
echo -e "${YELLOW}[*] Testing configurations...${NC}"
nginx -t >/dev/null 2>&1 || { 
    echo -e "${RED}[ERROR] Invalid NGINX configuration!${NC}" 
    exit 1 
} 

xray -test -config /etc/xray/config.json >/dev/null 2>&1 || { 
    echo -e "${RED}[ERROR] Invalid XRAY configuration!${NC}" 
    exit 1 
}

# ================= START SERVICE =================
systemctl daemon-reload
systemctl enable xray >/dev/null 2>&1
systemctl restart xray
systemctl restart nginx

sleep 2 

if ! systemctl is-active --quiet xray; then 
    echo -e "${RED}[ERROR] XRAY failed to start!${NC}" 
    journalctl -u xray -n 20 --no-pager 
    exit 1 
fi 

if ! systemctl is-active --quiet nginx; then 
    echo -e "${RED}[ERROR] NGINX failed to start!${NC}" 
    journalctl -u nginx -n 20 --no-pager 
    exit 1 
fi

# ================= INSTALL LOG =================
cat >> /root/log-install.txt <<EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
XRAY PANEL & PROTOCOLS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Domain              : $domain
XRAY VMess TLS      : 443
XRAY VMess None TLS : 80
XRAY VMess gRPC     : 443
XRAY VLESS TLS      : 443
XRAY VLESS None TLS : 80
XRAY VLESS gRPC     : 443
XRAY Trojan TLS     : 443
XRAY Trojan gRPC    : 443
XRAY SS WS TLS      : 443
XRAY SS WS None TLS : 80
XRAY SS WS gRPC     : 443
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF

clear

# ================= DONE =================
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[44;1;39m     XRAY INSTALLED SUCCESS        \E[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e " Domain        : ${CYAN}$domain${NC}"
echo -e " XRAY Config   : /etc/xray/config.json"
echo -e " NGINX Config  : /etc/nginx/conf.d/xray.conf"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""

sleep 3
exit 0
