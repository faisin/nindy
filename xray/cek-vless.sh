#!/bin/bash
# Cek login VLESS - by znandev

clear

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

LOG="/var/log/xray/access.log"
CONFIG="/etc/xray/config.json"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "\E[44;1;39m            CEK LOGIN VLESS USER             \E[0m"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Validasi file log & config
if [[ ! -f $LOG ]]; then
    echo -e "${RED}❌ Log file access.log tidak ditemukan!${NC}"
    echo ""
    read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."
    menu
fi

if [[ ! -f $CONFIG ]]; then
    echo -e "${RED}❌ File config.json tidak ditemukan!${NC}"
    echo ""
    read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."
    menu
fi

printf "%-15s %-18s\n" "USERNAME" "IP CLIENT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Mengambil daftar user dari tag inbounds vless yang sesuai dengan skrip add vless
users=$(jq -r '.inbounds[] | select(.tag=="vless-ws-tls" or .tag=="vless-grpc") | .settings.clients[].email' "$CONFIG" 2>/dev/null)

if [[ -z "$users" ]]; then
    echo -e "${YELLOW}Tidak ada pengguna VLESS yang terdaftar.${NC}"
else
    # Mengambil IP unik dari log akses
    ips=$(grep "accepted" "$LOG" 2>/dev/null \
    | awk -F'from ' '{print $2}' \
    | cut -d':' -f1 \
    | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' \
    | grep -v "127.0.0.1" \
    | sort -u)

    if [[ -z "$ips" ]]; then
        echo -e "${YELLOW}Tidak ada aktivitas koneksi aktif saat ini.${NC}"
    else
        for user in $users
        do
            for ip in $ips
            do
                printf "${GREEN}%-15s${NC} %-18s\n" "$user" "$ip"
            done
        done
    fi
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."

# Kembali ke menu utama
menu

