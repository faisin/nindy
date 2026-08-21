#!/bin/bash
# ==========================================
# Setup SSH WebSocket + UDPGW - by znandev
# ==========================================
set -e

GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

DEPS_VERSION="deps-v2"
RELEASE_URL="https://github.com/znandev/AutoscriptXRAY/releases/download/${DEPS_VERSION}"

clear

echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[44;1;39m     INSTALL SSH + WEBSOCKET       \E[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""

# ================= CHECK ROOT =================
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ Please run as root!${NC}"
   exit 1
fi

# ================= DETEKSI DIREKTORI REPO =================
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
if [[ ! -d "$REPO_DIR/config" ]]; then
    REPO_DIR="$HOME/nindy"
fi
if [[ ! -d "$REPO_DIR/config" ]]; then
    REPO_DIR="$HOME/AutoscriptXRAY"
fi
if [[ ! -d "$REPO_DIR/config" ]]; then
    REPO_DIR="/etc/autoscriptvpn"
fi

if [[ ! -f "$REPO_DIR/config/issue.net" ]]; then
    echo -e "${YELLOW}[!] File issue.net tidak ditemukan di direktori default, membuat baru...${NC}"
    mkdir -p "$REPO_DIR/config"
    echo -e "Authorized access only!\n" > "$REPO_DIR/config/issue.net"
fi

# ================= INSTALL DEPENDENCY =================
echo -e "${YELLOW}[*] Installing dependencies...${NC}"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y >/dev/null 2>&1 || true

apt-get install -y --no-install-recommends \
    openssh-server \
    stunnel4 \
    curl \
    wget \
    python3 \
    screen \
    git \
    golang-go \
    libtomcrypt1 \
    libtommath1 >/dev/null 2>&1 || true

mkdir -p /usr/local/bin

# ================= INSTALL DROPBEAR =================
echo -e "${YELLOW}[*] Installing Dropbear (2019.78)...${NC}"
systemctl stop dropbear 2>/dev/null || true

apt-get purge -y dropbear dropbear-bin >/dev/null 2>&1 || true
rm -f /usr/sbin/dropbear /usr/bin/dbclient /usr/bin/dropbearkey

cd /tmp
wget -qO dropbear-bin.deb "${RELEASE_URL}/dropbear-bin_2019.78-2build1_amd64.deb" || {
    echo -e "${RED}[ERROR] Failed to download dropbear-bin${NC}"
    exit 1
}

wget -qO dropbear.deb "${RELEASE_URL}/dropbear_2019.78-2build1_all.deb" || {
    echo -e "${RED}[ERROR] Failed to download dropbear${NC}"
    exit 1
}

dpkg -i dropbear-bin.deb dropbear.deb >/dev/null 2>&1

DROPBEAR_VER=$(dropbear -V 2>&1)
echo "$DROPBEAR_VER" | grep -q "2019.78" || {
    echo -e "${RED}[ERROR] Wrong Dropbear installed!${NC}"
    exit 1
}

# ================= HOSTKEY =================
mkdir -p /etc/dropbear
[ ! -f /etc/dropbear/dropbear_rsa_host_key ] && dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key >/dev/null 2>&1
[ ! -f /etc/dropbear/dropbear_ecdsa_host_key ] && dropbearkey -t ecdsa -f /etc/dropbear/dropbear_ecdsa_host_key >/dev/null 2>&1

# ================= BANNER =================
cp "$REPO_DIR/config/issue.net" /etc/issue.net
chmod 644 /etc/issue.net

# ================= DROPBEAR CONFIG =================
cat > /etc/default/dropbear <<EOF
NO_START=0
DROPBEAR_PORT=109
DROPBEAR_EXTRA_ARGS="-p 143 -W 65536 -b /etc/issue.net"
DROPBEAR_RECEIVE_WINDOW=65536
EOF

# ================= DROPBEAR SERVICE =================
cat > /etc/systemd/system/dropbear.service <<EOF
[Unit]
Description=Dropbear SSH Server - by znandev
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/sbin/dropbear -E -F -p 109 -p 143 -W 65536 -b /etc/issue.net
Restart=always
RestartSec=3s

[Install]
WantedBy=multi-user.target
EOF

# ================= BUILD GO WS =================
echo -e "${YELLOW}[*] Building Go WebSocket Services...${NC}"
if [[ -d "$REPO_DIR/internal/go" ]]; then
    cd "$REPO_DIR/internal/go"
    go build -ldflags="-s -w" -o /usr/local/bin/dropbearws ./dropbear-ws 2>/dev/null || true
    go build -ldflags="-s -w" -o /usr/local/bin/stunnelws ./stunnel-ws 2>/dev/null || true
fi

# Fallback jika binary belum terkompilasi
if [[ ! -f /usr/local/bin/dropbearws ]]; then
    echo -e "${RED}[ERROR] Gagal mengkompilasi dropbearws! Pastikan direktori sumber Go tersedia.${NC}"
    exit 1
fi

chmod +x /usr/local/bin/dropbearws
chmod +x /usr/local/bin/stunnelws

# ================= INSTALL BADVPN UDPGW =================
echo -e "${YELLOW}[*] Installing BadVPN UDPGW...${NC}"
wget -qO /usr/local/bin/badvpn-udpgw "${RELEASE_URL}/badvpn-udpgw" || {
    echo -e "${RED}[ERROR] Failed to download BadVPN UDPGW${NC}"
    exit 1
}
chmod +x /usr/local/bin/badvpn-udpgw

cat > /etc/systemd/system/badvpn.service <<EOF
[Unit]
Description=BadVPN UDPGW Service - by znandev
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 500 --max-connections-for-ip 20
Restart=always
RestartSec=3s

[Install]
WantedBy=multi-user.target
EOF

# ================= INSTALL UDP CUSTOM =================
echo -e "${YELLOW}[*] Installing UDP Custom...${NC}"
wget -qO /usr/local/bin/udp-custom "${RELEASE_URL}/udp-custom-linux-amd64" || {
    echo -e "${RED}[ERROR] Failed to download UDP Custom${NC}"
    exit 1
}
chmod +x /usr/local/bin/udp-custom

mkdir -p /etc/udp-custom
if [[ -f "$REPO_DIR/config/udp-custom.json" ]]; then
    cp "$REPO_DIR/config/udp-custom.json" /etc/udp-custom/config.json
else
    cat > /etc/udp-custom/config.json <<EOF
{
  "listen": ":36712",
  "stream_buffer": 2097152,
  "receive_buffer": 1048576
}
EOF
fi

cat > /etc/systemd/system/udp-custom.service <<EOF
[Unit]
Description=UDP Custom Service - by znandev
After=network.target nss-lookup.target

[Service]
User=root
Type=simple
WorkingDirectory=/etc/udp-custom
ExecStart=/usr/local/bin/udp-custom server -c /etc/udp-custom/config.json -exclude 7300
Restart=always
RestartSec=3s

[Install]
WantedBy=multi-user.target
EOF

# ================= GO WS SERVICES =================
cat > /etc/systemd/system/dropbearws.service <<EOF
[Unit]
Description=Go WS Dropbear Service - by znandev
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
WorkingDirectory=/usr/local/bin
ExecStart=/usr/local/bin/dropbearws
Restart=always
RestartSec=3s

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/stunnelws.service <<EOF
[Unit]
Description=Go WS Stunnel Service - by znandev
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
WorkingDirectory=/usr/local/bin
ExecStart=/usr/local/bin/stunnelws
Restart=always
RestartSec=3s

[Install]
WantedBy=multi-user.target
EOF

# ================= RELOAD & ENABLE =================
echo -e "${YELLOW}[*] Starting and enabling services...${NC}"
systemctl daemon-reload

services=(ssh dropbear dropbearws stunnelws badvpn udp-custom)
for svc in "${services[@]}"; do
    systemctl enable "$svc" >/dev/null 2>&1 || true
    systemctl restart "$svc" >/dev/null 2>&1 || true
done

# ================= CHECK SERVICES =================
sleep 2
for svc in "${services[@]}"; do
    if ! systemctl is-active --quiet "$svc"; then
        echo -e "${RED}[ERROR] Service $svc gagal dijalankan!${NC}"
        systemctl status "$svc" --no-pager | head -n 10
        exit 1
    fi
done

# ================= NOLOGIN WS =================
cat > /etc/profile.d/no-login.sh <<'EOF'
#!/bin/bash
[[ "$USER" == "root" ]] && return
clear
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " ❌ SSH WS ACCOUNT ONLY - SHELL DENIED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
sleep 2
pkill -9 -u "$USER"
EOF
chmod +x /etc/profile.d/no-login.sh

# ================= HOLD DROPBEAR =================
apt-mark hold dropbear dropbear-bin >/dev/null 2>&1 || true

sleep 3
exit 0
