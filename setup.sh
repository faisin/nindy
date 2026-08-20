#!/bin/bash
# ==========================================
# Setup Script XRAY_AIO (Fixed Flow Version)
# XRAY + WireGuard + UDP ZIVPN
# ==========================================

echo "" > /root/log-install.txt
cd "$(dirname "$0")"
clear

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

if [ "$(systemd-detect-virt)" == "openvz" ]; then
    error "OpenVZ tidak didukung. Gunakan KVM/VMWare."
    exit 1
fi

# Fix /etc/hosts
localip=$(hostname -I | awk '{print $1}')
hostname=$(hostname)
domainline=$(grep -w "$hostname" /etc/hosts | awk '{print $2}')
if [[ "$hostname" != "$domainline" ]]; then
    echo "$localip $hostname" >> /etc/hosts
fi

# Create Folders
mkdir -p /etc/xray /etc/v2ray /var/lib
for file in domain scdomain; do
    touch /etc/xray/$file /etc/v2ray/$file /root/$file
done
touch /var/lib/ipvps.conf

ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

# Update & Install Packages (UFW dihapus agar tidak konflik)
info "Installing dependencies..."
apt update -y
apt install -y \
curl \
wget \
git \
screen \
unzip \
bzip2 \
gzip \
coreutils \
python3 \
python3-pip \
iptables \
iptables-persistent \
netfilter-persistent \
vnstat \
openssl || { error "Gagal menginstal dependencies utama"; exit 1; }

# Install Linux Header
kernelver=$(uname -r)
headerpkg="linux-headers-$kernelver"
if ! dpkg -s $headerpkg >/dev/null 2>&1; then
    info "Installing $headerpkg..."
    apt install -y $headerpkg
fi

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
for dfile in domain scdomain; do
    echo "$domain" > /etc/xray/$dfile
    echo "$domain" > /etc/v2ray/$dfile
    echo "$domain" > /root/$dfile
done
echo "IP=$domain" > /var/lib/ipvps.conf

info "Domain berhasil diset: $domain"
sleep 2

# ==========================================
# RUN INSTALLER MODULES
# ==========================================
info "Menjalankan instalasi modul..."

if [ -f "install/nginx.sh" ]; then
    bash install/nginx.sh
else
    warn "install/nginx.sh tidak ditemukan!"
fi

if [ -f "install/xray.sh" ]; then
    bash install/xray.sh
else
    warn "install/xray.sh tidak ditemukan!"
fi

if [ -f "install/ssh.sh" ]; then
    bash install/ssh.sh
else
    warn "install/ssh.sh tidak ditemukan!"
fi

if [ -f "install/wg.sh" ]; then
    bash install/wg.sh
else
    warn "install/wg.sh tidak ditemukan!"
fi

if [ -f "install/zivpn.sh" ]; then
    bash install/zivpn.sh
else
    warn "install/zivpn.sh tidak ditemukan!"
fi

# ==========================================
# COPY MENU & SUBMENU COMMANDS
# ==========================================
info "Menyalin command menu..."

[ -f "ssh/m-ssh" ] && cp -f ssh/m-ssh /usr/bin/
[ -f "xray/m-vmess" ] && cp -f xray/m-vmess /usr/bin/
[ -f "xray/m-vless" ] && cp -f xray/m-vless /usr/bin/
[ -f "xray/m-trojan" ] && cp -f xray/m-trojan /usr/bin/
[ -f "xray/m-ssws" ] && cp -f xray/m-ssws /usr/bin/
[ -f "wg/m-wg" ] && cp -f wg/m-wg /usr/bin/
[ -f "udp/m-zivpn" ] && cp -f udp/m-zivpn /usr/bin/

[ -f "tools/tools-menu" ] && cp -f tools/tools-menu /usr/bin/
[ -f "tools/backup.sh" ] && cp -f tools/backup.sh /usr/bin/
[ -f "tools/speedtest.sh" ] && cp -f tools/speedtest.sh /usr/bin/
[ -f "tools/domain.sh" ] && cp -f tools/domain.sh /usr/bin/
[ -f "tools/running.sh" ] && cp -f tools/running.sh /usr/bin/

if [ -f "menu.sh" ]; then
    cp -f menu.sh /usr/bin/menu
else
    error "File menu.sh tidak ditemukan di repository!"
fi

# Set Permissions
chmod +x /usr/bin/menu 2>/dev/null
for cmd in m-ssh m-vmess m-vless m-trojan m-ssws m-wg m-zivpn tools-menu backup.sh speedtest.sh domain.sh running.sh; do
    [ -f "/usr/bin/$cmd" ] && chmod +x "/usr/bin/$cmd"
done

# Copy Runtime Submenus to /etc/autoscriptvpn/
info "Menyalin sub-skrip ke direktori sistem..."
mkdir -p /etc/autoscriptvpn/{ssh,xray,wg,udp,tools}

[ -d "ssh" ] && cp -r ssh/* /etc/autoscriptvpn/ssh/ 2>/dev/null
[ -d "xray" ] && cp -r xray/* /etc/autoscriptvpn/xray/ 2>/dev/null
[ -d "wg" ] && cp -r wg/* /etc/autoscriptvpn/wg/ 2>/dev/null
[ -d "udp" ] && cp -r udp/* /etc/autoscriptvpn/udp/ 2>/dev/null
[ -d "tools" ] && cp -r tools/* /etc/autoscriptvpn/tools/ 2>/dev/null

chmod +x /etc/autoscriptvpn/*/*.sh 2>/dev/null

# Auto Menu Login via .profile
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

# Clean up temp files
rm -f cf ins-xray.sh

# Finish
end_time=$(date +%s)
elapsed=$((end_time - start_time))
clear

echo -e "${blue}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${green}      INSTALLATION DONE${NC}"
echo -e "${blue}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e " SSH         : INSTALLED"
echo -e " XRAY        : INSTALLED"
echo -e " WireGuard   : INSTALLED"
echo -e " UDP ZIVPN   : INSTALLED"
echo ""
echo -e " Waktu Instalasi : $((elapsed / 60)) menit $((elapsed % 60)) detik"
echo -e "${blue}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${green}♻️ VPS akan reboot dalam 10 detik...${NC}"

sleep 10
reboot
