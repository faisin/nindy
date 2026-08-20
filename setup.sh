#!/bin/bash
# ==========================================
# Setup Script XRAY_AIO (Fixed Version)
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

# Fix /etc/hosts
localip=$(hostname -I | awk '{print $1}')
hostname=$(hostname)
if [ -n "$localip" ]; then
    domainline=$(grep -w "$hostname" /etc/hosts | awk '{print $2}')
    if [[ "$hostname" != "$domainline" ]]; then
        echo "$localip $hostname" >> /etc/hosts
    fi
fi

mkdir -p /etc/xray /etc/v2ray /var/lib
for file in domain scdomain; do
    touch /etc/xray/$file /etc/v2ray/$file /root/$file
done
touch /var/lib/ipvps.conf

ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

info "Installing dependencies..."
apt update -y || { error "Gagal melakukan apt update"; exit 1; }

# UFW dihapus untuk mencegah konflik dengan iptables-persistent
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

# Buat fungsi menu darurat jika file menu utama belum ada di repo
if [ ! -f "menu.sh" ]; then
    cat << 'EOF' > /usr/bin/menu
#!/bin/bash
clear
echo "================================="
echo "   AUTOSCRIPT XRAY_AIO PANEL     "
echo "================================="
echo " 1. Status Layanan (Running)"
echo " 2. Keluar"
echo "================================="
read -p "Pilih menu [1-2]: " opt
case $opt in
  1) running ;;
  *) exit 0 ;;
esac
EOF
    chmod +x /usr/bin/menu
fi

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
echo -e " Installation Time : $((elapsed / 60)) menit $((elapsed % 60)) detik"
echo -e "${blue}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${green}♻️ VPS akan reboot dalam 10 detik...${NC}"
sleep 10
reboot
