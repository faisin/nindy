#!/bin/bash
# Delete VMess Account - by znandev
set -e

clear

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

CONFIG="/etc/xray/config.json"
DB_FILE="/etc/xray/vmess.db"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "\E[44;1;39m            DELETE VMESS ACCOUNT             \E[0m"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${CYAN}📋 List User VMess:${NC}"
echo ""

# Mengambil user dari tag inbounds vmess yang sesuai
users=$(jq -r '.inbounds[] | select(.tag=="vmess-ws-tls" or .tag=="vmess-ws-nontls" or .tag=="vmess-grpc") | .settings.clients[].email' "$CONFIG" 2>/dev/null | sort -u)

if [[ -z "$users" ]]; then
    echo -e "${RED}Tidak ada user VMess!${NC}"
    echo ""
    read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."
    menu
fi

num=1
for user in $users; do
    printf "${GREEN}[%s]${NC} %s\n" "$num" "$user"
    ((num++))
done

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
read -rp "👉 Masukkan username yang ingin dihapus: " user
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Validasi apakah user ada
CLIENT_EXISTS=$(jq -r '.inbounds[] | select(.tag=="vmess-ws-tls" or .tag=="vmess-ws-nontls" or .tag=="vmess-grpc") | .settings.clients[]?.email' "$CONFIG" 2>/dev/null | grep -w "$user" | wc -l)

if [[ ${CLIENT_EXISTS} == '0' ]]; then
    echo -e "\n${RED}❌ Akun VMess '${user}' tidak ditemukan!${NC}"
    echo ""
    read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."
    menu
fi

# Backup config
cp "$CONFIG" "${CONFIG}.bak"

# Temp file untuk jq
tmpfile=$(mktemp)

# Hapus user dari inbounds VMess menggunakan jq
if ! jq --arg user "$user" '
(.inbounds[] | select(.tag=="vmess-ws-tls").settings.clients) |= [ .[] | select(.email != $user) ] |
(.inbounds[] | select(.tag=="vmess-ws-nontls").settings.clients) |= [ .[] | select(.email != $user) ] |
(.inbounds[] | select(.tag=="vmess-grpc").settings.clients) |= [ .[] | select(.email != $user) ]
' "$CONFIG" > "$tmpfile"; then
    echo -e "\n${RED}ERROR: Gagal memproses konfigurasi dengan jq!${NC}"
    rm -f "$tmpfile"
    exit 1
fi

# Validasi hasil json sementara
if ! jq empty "$tmpfile" >/dev/null 2>&1; then
    echo -e "\n${RED}ERROR: Hasil konfigurasi JSON tidak valid!${NC}"
    rm -f "$tmpfile"
    exit 1
fi

# Timpa config lama
mv "$tmpfile" "$CONFIG"

# Test konfigurasi Xray
if ! xray -test -config "$CONFIG" >/dev/null 2>&1; then
    echo -e "\n${RED}ERROR: Tes konfigurasi Xray gagal! Mengembalikan cadangan...${NC}"
    cp "${CONFIG}.bak" "$CONFIG"
    exit 1
fi

# Restart Xray
systemctl restart xray

# Hapus data dari database lokal vmess.db jika ada
if [ -f "$DB_FILE" ]; then
    grep -v "^$user " "$DB_FILE" > "${DB_FILE}.tmp" && mv "${DB_FILE}.tmp" "$DB_FILE"
fi

echo ""
echo -e "${GREEN}✅ User VMess '${user}' berhasil dihapus!${NC}"
echo ""

read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."

# Kembali ke menu utama
menu

