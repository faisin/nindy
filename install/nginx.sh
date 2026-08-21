#!/bin/bash
# ==========================================
# Install Nginx Reverse Proxy - by znandev
# ==========================================
set -e

GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

clear

echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[44;1;39m    INSTALL NGINX REVERSE PROXY    \E[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""

# ================= CHECK ROOT =================
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ Please run as root!${NC}"
   exit 1
fi

# ================= DETEKSI DIREKTORI REPO =================
BASE_DIR="$HOME/AutoscriptXRAY"
if [[ ! -d "$BASE_DIR" ]]; then
    BASE_DIR="/etc/autoscriptvpn"
fi

if [[ ! -d "$BASE_DIR" ]]; then
    echo -e "${RED}[ERROR] Direktori repositori tidak ditemukan! Pastikan repo sudah disalin.${NC}"
    exit 1
fi

echo -e "${YELLOW}[*] Memulai instalasi NGINX...${NC}"

# ================= INSTALL NGINX =================
export DEBIAN_FRONTEND=noninteractive
apt-get update -y >/dev/null 2>&1 || true

apt-get install -y --no-install-recommends \
    nginx \
    curl \
    wget >/dev/null 2>&1 || true

# ================= REMOVE DEFAULT CONFIG =================
rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-available/default

# ================= CREATE DIR =================
mkdir -p /etc/nginx/conf.d

# ================= COPY MAIN NGINX CONFIG =================
if [[ ! -f "$BASE_DIR/config/nginx.conf" ]]; then
    echo -e "${RED}[ERROR] nginx.conf tidak ditemukan di $BASE_DIR/config/!${NC}"
    exit 1
fi

cp "$BASE_DIR/config/nginx.conf" /etc/nginx/nginx.conf
chmod 644 /etc/nginx/nginx.conf

# ================= TEST CONFIG =================
echo -e "${YELLOW}[*] Testing Nginx Configuration...${NC}"
nginx -t >/dev/null 2>&1 || {
    echo -e "${RED}❌ Nginx config error! Jalankan 'nginx -t' manual untuk melihat detail error.${NC}"
    exit 1
}

# ================= ENABLE SERVICE =================
systemctl daemon-reload
systemctl enable nginx >/dev/null 2>&1
systemctl restart nginx

sleep 2

if ! systemctl is-active --quiet nginx; then
    echo -e "${RED}[ERROR] NGINX gagal dijalankan!${NC}"
    systemctl status nginx --no-pager | head -n 10
    exit 1
fi

clear

# ================= SUMMARY =================
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[44;1;39m    NGINX INSTALLED SUCCESS        \E[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e " Status        : ${GREEN}RUNNING (ONLINE)${NC}"
echo -e " Main Config   : /etc/nginx/nginx.conf"
echo -e " Conf.d Path   : /etc/nginx/conf.d/"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""

sleep 3
exit 0
