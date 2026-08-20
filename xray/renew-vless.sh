#!/bin/bash
# Perpanjang akun VLESS - by znandev
set -e

clear

BLUE='\033[0;34m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

CONFIG="/etc/xray/config.json"
DB_FILE="/etc/xray/vless.db"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "\E[44;1;39m            PERPANJANG AKUN VLESS            \E[0m"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${CYAN}📋 Daftar User VLESS:${NC}"
echo ""

# Ambil user dari tag inbounds vless yang sesuai
users=$(jq -r '.inbounds[] | select(.tag=="vless-ws-tls" or .tag=="vless-ws-nontls" or .tag=="vless-grpc") | .settings.clients[].email' "$CONFIG" 2>/dev/null | sort -u)

if [[ -z "$users" ]]; then
    echo -e "${RED}Tidak ada user VLESS!${NC}"
    echo ""
    read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."
    menu
fi

for user in $users
do
    echo -e " - ${GREEN}$user${NC}"
done

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

read -rp "Masukkan username yang ingin diperpanjang: " user

# Validasi apakah user ada di config dan database
CLIENT_EXISTS=$(jq -r '.inbounds[] | select(.tag=="vless-ws-tls" or .tag=="vless-ws-nontls" or .tag=="vless-grpc") | .settings.clients[]?.email' "$CONFIG" 2>/dev/null | grep -w "$user" | wc -l)

if [[ ${CLIENT_EXISTS} == '0' ]]; then
    echo -e "\n${RED}❌ User '$user' tidak ditemukan!${NC}"
    echo ""
    read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."
    menu
fi

read -rp "Tambahkan masa aktif (hari): " tambah

# Validasi input angka
if ! [[ "$tambah" =~ ^[0-9]+$ ]]; then
    echo -e "\n${RED}❌ Masukkan angka hari yang valid!${NC}"
    echo ""
    read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."
    menu
fi

# Cek data di database vless.db jika ada, jika tidak buat estimasi dari hari ini
if [ -f "$DB_FILE" ] && grep -q "^$user " "$DB_FILE"; then
    old_data=$(grep -w "^$user" "$DB_FILE")
    exp_now=$(echo "$old_data" | awk '{print $2}')
    uuid=$(echo "$old_data" | awk '{print $3}')
    
    exp_ts=$(date -d "$exp_now" +%s 2>/dev/null || date +%s)
    now_ts=$(date +%s)

    if [ $exp_ts -lt $now_ts ]; then
        new_exp=$(date -d "+$tambah days" +%Y-%m-%d)
    else
        new_exp=$(date -d "$exp_now + $tambah days" +%Y-%m-%d)
    fi

    # Update database
    grep -v "^$user " "$DB_FILE" > "${DB_FILE}.tmp"
    echo "${user} ${new_exp} ${uuid}" >> "${DB_FILE}.tmp"
    mv "${DB_FILE}.tmp" "$DB_FILE"
else
    new_exp=$(date -d "+$tambah days" +%Y-%m-%d)
    uuid=$(jq -r --arg user "$user" '.inbounds[] | select(.tag=="vless-ws-tls" or .tag=="vless-ws-nontls" or .tag=="vless-grpc") | .settings.clients[]? | select(.email == $user) | .id' "$CONFIG" | head -n 1)
    mkdir -p /etc/xray
    echo "${user} ${new_exp} ${uuid}" >> "$DB_FILE"
fi

systemctl restart xray

clear
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "\E[44;1;39m            AKUN BERHASIL DIPERPANJANG       \E[0m"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "User      : ${GREEN}$user${NC}"
echo -e "Expired   : ${GREEN}$new_exp${NC}"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."

# Kembali ke menu utama
menu

