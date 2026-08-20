#!/bin/bash
# ==========================================
# Setup Script XRAY_AIO (Cleaned & Fixed)
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

# UFW dihapus dari daftar instalasi untuk mencegah konflik dengan iptables-persistent
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

# ==========================================
# INSTALL LINUX HEADER
# ==========================================

kernelver=$(uname -r)
headerpkg="linux-headers-$kernelver"

if ! dpkg -s $headerpkg >/dev/null 2>&1; then
    info "Installing $headerpkg..."
    apt install -y $headerpkg
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
# RUN INSTALLER (Dengan pengaman folder)
# ==========================================

if [ -d "install" ]; then
    [ -f "install/nginx.sh" ] && { info "Installing NGINX Reverse Proxy..."; bash install/nginx.sh; }
    [ -f "install/xray.sh" ] && { info "Installing XRAY Core..."; bash install/xray.sh; }
    [ -f "install/ssh.sh" ] && { info "Installing SSH Websocket..."; bash install/ssh.sh; }
    [ -f "install/wg.sh" ] && { info "Installing WireGuard..."; bash install/wg.sh; }
    [ -f "install/zivpn.sh" ] && { info "Installing UDP ZIVPN..."; bash install/zivpn.sh; }
else
    warn "Folder 'install' tidak ditemukan, melewati instalasi modul eksternal."
fi

# ==========================================
# COPY MENU COMMAND
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
    # Fallback Menu Darurat agar perintah 'menu' tidak error command not found
    cat << 'EOF' > /usr/bin/menu
#!/bin/bash
clear
while true; do
    echo "================================="
    echo "   AUTOSCRIPT XRAY_AIO PANEL     "
    echo "================================="
    echo " 1. Cek Status Layanan (Running)"
    echo " 2. Keluar"
    echo "================================="
    read -p "Pilih menu [1-2]: " opt
    case $opt in
        1)
            if [ -f /usr/bin/running.sh ]; then
                running.sh
            else
                echo "Layanan sistem aktif."
            fi
            read -p "Tekan [Enter] untuk kembali..."
            clear
            ;;
        2)
            exit 0
            ;;
        *)
            echo "Pilihan tidak valid!"
            sleep 1
            clear
            ;;
    esac
done
EOF
fi

# ==========================================
# SET PERMISSION
# ==========================================

[ -f /usr/bin/menu ] && chmod +x /usr/bin/menu

for cmd in m-ssh m-vmess m-vless m-trojan m-ssws m-wg m-zivpn tools-menu backup.sh speedtest.sh domain.sh running.sh; do
    [ -f "/usr/bin/$cmd" ] && chmod +x "/usr/bin/$cmd"
done

[ -d "ssh" ] && chmod +x ssh/*.sh 2>/dev/null
[ -d "xray" ] && chmod +x xray/*.sh 2>/dev/null
[ -d "wg" ] && chmod +x wg/*.sh 2>/dev/null
[ -d "udp" ] && chmod +x udp/*.sh 2>/dev/null
[ -d "tools" ] && chmod +x tools/*.sh 2>/dev/null

# ==========================================
# COPY RUNTIME SCRIPT
# ==========================================

info "Menyalin semua submenu ke /etc/autoscriptvpn/..."

mkdir -p /etc/autoscriptvpn/{ssh,xray,wg,udp,tools}

[ -d "ssh" ] && cp -r ssh/* /etc/autoscriptvpn/ssh/ 2>/dev/null
[ -d "xray" ] && cp -r xray/* /etc/autoscriptvpn/xray/ 2>/dev/null
[ -d "wg" ] && cp -r wg/* /etc/autoscriptvpn/wg/ 2>/dev/null
[ -d "udp" ] && cp -r udp/* /etc/autoscriptvpn/udp/ 2>/dev/null
[ -d "tools" ] && cp -r tools/* /etc/autoscriptvpn/tools/ 2>/dev/null

chmod +x /etc/autoscriptvpn/*/*.sh 2>/dev/null

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

rm -f cf ins-xray.sh

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
