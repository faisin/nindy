#!/bin/bash
# ==========================================
# Setup Script XRAY_AIO (Fixed Execution Path)
# ==========================================

export DEBIAN_FRONTEND=noninteractive

red='\e[1;31m'
green='\e[0;32m'
yellow='\e[1;33m'
blue='\e[1;34m'
cyan='\e[1;36m'
NC='\e[0m'

function info() { echo -e "${green}[INFO]${NC} $1"; }
function warn() { echo -e "${yellow}[WARNING]${NC} $1"; }
function error() { echo -e "${red}[ERROR]${NC} $1"; }

start_time=$(date +%s)

if [ "${EUID}" -ne 0 ]; then
    error "Script harus dijalankan sebagai root."
    exit 1
fi

# Tentukan direktori tempat script dijalankan (folder nindy)
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$BASE_DIR"

clear

# Buat direktori dasar
mkdir -p /etc/xray /etc/v2ray /var/lib
touch /etc/xray/domain /etc/v2ray/domain /root/domain /var/lib/ipvps.conf
ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

# Update & Install Dependencies Dasar
info "Installing system dependencies..."
apt update -y
apt install -y curl wget git screen unzip bzip2 gzip coreutils python3 iptables iptables-persistent netfilter-persistent vnstat openssl || { error "Gagal menginstal dependencies"; exit 1; }

# Domain Setup
clear
echo -e "${blue}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${cyan}         DOMAIN SETUP${NC}"
echo -e "${blue}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

read -rp "Masukkan domain kamu : " domain
if [[ -z "$domain" ]]; then
    error "Domain tidak boleh kosong!"
    exit 1
fi

echo "$domain" > /root/domain
echo "$domain" > /etc/xray/domain
echo "$domain" > /etc/v2ray/domain
echo "IP=$domain" > /var/lib/ipvps.conf

info "Domain berhasil diset: $domain"
sleep 2

# ==========================================
# EKSEKUSI MODUL INSTALASI SECARA BERURUTAN
# ==========================================
info "Menjalankan modul instalasi..."

# 1. Nginx
if [ -f "$BASE_DIR/install/nginx.sh" ]; then
    bash "$BASE_DIR/install/nginx.sh"
else
    error "install/nginx.sh tidak ditemukan!"
    exit 1
fi

# 2. Xray
if [ -f "$BASE_DIR/install/xray.sh" ]; then
    bash "$BASE_DIR/install/xray.sh"
else
    error "install/xray.sh tidak ditemukan!"
    exit 1
fi

# 3. SSH
if [ -f "$BASE_DIR/install/ssh.sh" ]; then
    bash "$BASE_DIR/install/ssh.sh"
else
    error "install/ssh.sh tidak ditemukan!"
    exit 1
fi

# 4. WireGuard
if [ -f "$BASE_DIR/install/wg.sh" ]; then
    bash "$BASE_DIR/install/wg.sh"
else
    error "install/wg.sh tidak ditemukan!"
    exit 1
fi

# 5. ZiVPN
if [ -f "$BASE_DIR/install/zivpn.sh" ]; then
    bash "$BASE_DIR/install/zivpn.sh"
else
    error "install/zivpn.sh tidak ditemukan!"
    exit 1
fi

# ==========================================
# MENYALIN FILE MENU & COMMANDS
# ==========================================
info "Menyalin command menu..."

[ -f "$BASE_DIR/ssh/m-ssh" ] && cp -f "$BASE_DIR/ssh/m-ssh" /usr/bin/
[ -f "$BASE_DIR/xray/m-vmess" ] && cp -f "$BASE_DIR/xray/m-vmess" /usr/bin/
[ -f "$BASE_DIR/xray/m-vless" ] && cp -f "$BASE_DIR/xray/m-vless" /usr/bin/
[ -f "$BASE_DIR/xray/m-trojan" ] && cp -f "$BASE_DIR/xray/m-trojan" /usr/bin/
[ -f "$BASE_DIR/xray/m-ssws" ] && cp -f "$BASE_DIR/xray/m-ssws" /usr/bin/
[ -f "$BASE_DIR/wg/m-wg" ] && cp -f "$BASE_DIR/wg/m-wg" /usr/bin/
[ -f "$BASE_DIR/udp/m-zivpn" ] && cp -f "$BASE_DIR/udp/m-zivpn" /usr/bin/

[ -f "$BASE_DIR/tools/tools-menu" ] && cp -f "$BASE_DIR/tools/tools-menu" /usr/bin/
[ -f "$BASE_DIR/tools/backup.sh" ] && cp -f "$BASE_DIR/tools/backup.sh" /usr/bin/
[ -f "$BASE_DIR/tools/speedtest.sh" ] && cp -f "$BASE_DIR/tools/speedtest.sh" /usr/bin/
[ -f "$BASE_DIR/tools/domain.sh" ] && cp -f "$BASE_DIR/tools/domain.sh" /usr/bin/
[ -f "$BASE_DIR/tools/running.sh" ] && cp -f "$BASE_DIR/tools/running.sh" /usr/bin/

if [ -f "$BASE_DIR/menu.sh" ]; then
    cp -f "$BASE_DIR/menu.sh" /usr/bin/menu
else
    error "File menu.sh tidak ditemukan!"
fi

# Berikan izin eksekusi
chmod +x /usr/bin/menu 2>/dev/null
for cmd in m-ssh m-vmess m-vless m-trojan m-ssws m-wg m-zivpn tools-menu backup.sh speedtest.sh domain.sh running.sh; do
    [ -f "/usr/bin/$cmd" ] && chmod +x "/usr/bin/$cmd"
done

# Set Profile Auto Login Menu
cat > /root/.profile <<-EOF
if [ "\$BASH" ]; then
    if [ -f ~/.bashrc ]; then
        . ~/.bashrc
    fi
fi
clear
menu
EOF
chmod 644 /root/.profile

# Selesai
end_time=$(date +%s)
elapsed=$((end_time - start_time))
clear

echo -e "${blue}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${green}      INSTALLATION DONE${NC}"
echo -e "${blue}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e " NGINX & XRAY : INSTALLED & RUNNING"
echo -e " SSH & TUNNEL : INSTALLED & RUNNING"
echo -e " WireGuard   : INSTALLED & RUNNING"
echo -e " UDP ZIVPN   : INSTALLED & RUNNING"
echo ""
echo -e " Waktu Instalasi : $((elapsed / 60)) menit $((elapsed % 60)) detik"
echo -e "${blue}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${green}♻️ VPS akan reboot dalam 5 detik...${NC}"

sleep 5
reboot
