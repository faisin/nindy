#!/bin/bash
# ==========================================
# Setup Script XRAY_AIO
# XRAY + WireGuard + UDP ZIVPN
# ==========================================

echo "" > /root/log-install.txt

cd "$(dirname "$0")"

clear

# ==========================================
# COLOR
# ==========================================

red='\e[1;31m'
green='\e[0;32m'
yellow='\e[1;33m'
blue='\e[1;34m'
cyan='\e[1;36m'
NC='\e[0m'

# ==========================================
# FUNCTION
# ==========================================

function info() {
    echo -e "${green}[INFO]${NC} $1"
}

function warn() {
    echo -e "${yellow}[WARNING]${NC} $1"
}

function error() {
    echo -e "${red}[ERROR]${NC} $1"
}

# ==========================================
# TIMER
# ==========================================

start_time=$(date +%s)

# ==========================================
# CHECK ROOT
# ==========================================

if [ "${EUID}" -ne 0 ]; then
    error "Script harus dijalankan sebagai root."
    exit 1
fi

# ==========================================
# CHECK VIRTUALIZATION
# ==========================================

if [ "$(systemd-detect-virt)" == "openvz" ]; then
    error "OpenVZ tidak didukung. Gunakan KVM/VMWare."
    exit 1
fi

# ==========================================
# FIX /etc/hosts
# ==========================================

localip=$(hostname -I | awk '{print $1}')
hostname=$(hostname)

domainline=$(grep -w "$hostname" /etc/hosts | awk '{print $2}')

if [[ "$hostname" != "$domainline" ]]; then
    echo "$localip $hostname" >> /etc/hosts
fi

# ==========================================
# CREATE REQUIRED FOLDER
# ==========================================

mkdir -p /etc/xray
mkdir -p /etc/v2ray
mkdir -p /var/lib

for file in domain scdomain; do
    touch /etc/xray/$file
    touch /etc/v2ray/$file
    touch /root/$file
done

touch /var/lib/ipvps.conf

# ==========================================
# SET TIMEZONE
# ==========================================

ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

# ==========================================
# UPDATE & INSTALL PACKAGE
# ==========================================

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
openssl \
ufw >/dev/null 2>&1

# ==========================================
#if ! dpkg -s $headerpkg >/dev/null 2>&1; then
    info "Installing $headerpkg..."
    apt install -y $headerpkg || apt install -y linux-headers-amd64 || true
fi

# ==========================================
# DOMAIN SETUP
# ==========================================

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

echo ""
info "Domain berhasil diset: $domain"

sleep 2
# ==========================================
# PROSES LAYANAN ANAK SASAK SEDANG BERJALAN
# ==========================================

info "Sedang memasang NGINX Reverse Proxy..."
bash <(wget -qO- https://raw.githubusercontent.com/faisin/nindy/main/install/nginx.sh)

info "Sedang memasang XRAY Core..."
bash <(wget -qO- https://raw.githubusercontent.com/faisin/nindy/main/install/xray.sh)

info "Sedang memasang SSH Websocket..."
bash <(wget -qO- https://raw.githubusercontent.com/faisin/nindy/main/install/ssh.sh)

info "Sedang memasang WireGuard..."
bash <(wget -qO- https://raw.githubusercontent.com/faisin/nindy/main/install/wg.sh)

info "Sedang memasang UDP ZIVPN..."
wget -O /etc/issue.net https://raw.githubusercontent.com/faisin/nindy/main/ssh/issue.net || touch /etc/issue.net
bash <(wget -qO- https://raw.githubusercontent.com/faisin/nindy/main/install/zivpn.sh)

# ==========================================
# COPY MENU COMMAND
# ==========================================
info "Mengunduh file menu dan submenu ke sistem..."

wget -O /usr/bin/menu https://raw.githubusercontent.com/faisin/nindy/main/menu.sh
chmod +x /usr/bin/menu

wget -O /usr/bin/m-ssh https://raw.githubusercontent.com/faisin/nindy/main/ssh/m-ssh
chmod +x /usr/bin/m-ssh

wget -O /usr/bin/m-vmess https://raw.githubusercontent.com/faisin/nindy/main/xray/m-vmess
chmod +x /usr/bin/m-vmess

wget -O /usr/bin/m-vless https://raw.githubusercontent.com/faisin/nindy/main/xray/m-vless
chmod +x /usr/bin/m-vless

wget -O /usr/bin/m-trojan https://raw.githubusercontent.com/faisin/nindy/main/xray/m-trojan
chmod +x /usr/bin/m-trojan

wget -O /usr/bin/m-ssws https://raw.githubusercontent.com/faisin/nindy/main/xray/m-ssws
chmod +x /usr/bin/m-ssws

wget -O /usr/bin/m-wg https://raw.githubusercontent.com/faisin/nindy/main/wg/m-wg
chmod +x /usr/bin/m-wg

wget -O /usr/bin/m-zivpn https://raw.githubusercontent.com/faisin/nindy/main/udp/m-zivpn
chmod +x /usr/bin/m-zivpn

wget -O /usr/bin/tools-menu https://raw.githubusercontent.com/faisin/nindy/main/tools/tools-menu
chmod +x /usr/bin/tools-menu

wget -O /usr/bin/backup.sh https://raw.githubusercontent.com/faisin/nindy/main/tools/backup.sh
chmod +x /usr/bin/backup.sh

wget -O /usr/bin/speedtest.sh https://raw.githubusercontent.com/faisin/nindy/main/tools/speedtest.sh
chmod +x /usr/bin/speedtest.sh

wget -O /usr/bin/domain.sh https://raw.githubusercontent.com/faisin/nindy/main/tools/domain.sh
chmod +x /usr/bin/domain.sh

wget -O /usr/bin/running.sh https://raw.githubusercontent.com/faisin/nindy/main/tools/running.sh
chmod +x /usr/bin/running.sh

# ==========================================
# SET PERMISSION
# ==========================================

chmod +x /usr/bin/menu

chmod +x /usr/bin/m-ssh
chmod +x /usr/bin/m-vmess
chmod +x /usr/bin/m-vless
chmod +x /usr/bin/m-trojan
chmod +x /usr/bin/m-ssws
chmod +x /usr/bin/m-wg
chmod +x /usr/bin/m-zivpn

chmod +x /usr/bin/tools-menu
chmod +x /usr/bin/backup.sh
chmod +x /usr/bin/speedtest.sh
chmod +x /usr/bin/domain.sh
chmod +x /usr/bin/running.sh

chmod +x ssh/*.sh
chmod +x xray/*.sh
chmod +x wg/*.sh
chmod +x udp/*.sh
chmod +x tools/*.sh

# ==========================================
# COPY RUNTIME SCRIPT
# ==========================================

info "Menyalin semua submenu ke /etc/autoscriptvpn/..."

mkdir -p /etc/autoscriptvpn/{ssh,xray,wg,udp,tools}

cp -r ssh/* /etc/autoscriptvpn/ssh/
cp -r xray/* /etc/autoscriptvpn/xray/
cp -r wg/* /etc/autoscriptvpn/wg/
cp -r udp/* /etc/autoscriptvpn/udp/
cp -r tools/* /etc/autoscriptvpn/tools/

chmod +x /etc/autoscriptvpn/*/*.sh

# ==========================================
# AUTO MENU LOGIN
# ==========================================

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

# ==========================================
# CLEAN FILE
# ==========================================

rm -f cf
rm -f ins-xray.sh

# ==========================================
# FINISH
# ==========================================

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
echo -e " Installation Time : $((elapsed / 60)) menit $((elapsed % 60)) detik"

echo -e "${blue}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo ""
echo -e "${green}♻️ VPS akan reboot dalam 10 detik...${NC}"

sleep 10

reboot
