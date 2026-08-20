#!/bin/bash
# ==========================================
# ADD ZIVPN USER - by znandev
# ==========================================
set -e

DB="/etc/zivpn/users.db"

clear

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m'

echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[44;1;39m          ADD ZIVPN USER           \E[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""

# Pastikan direktori database tersedia
mkdir -p /etc/zivpn
touch "$DB"

# ==============================
# INPUT USER & VALIDATION
# ==============================
until [[ $user =~ ^[a-zA-Z0-9_]+$ ]]; do
    read -rp "Username       : " user
done

# Check existing user
if grep -wq "^$user" "$DB"; then
    echo -e "\n${RED}❌ User already exists!${NC}"
    echo ""
    read -n 1 -s -r -p "Tekan apa saja untuk kembali..."
    m-zivpn
fi

read -rp "Expired (days) : " days

# Validasi input angka hari
if ! [[ "$days" =~ ^[0-9]+$ ]]; then
    echo -e "\n${RED}❌ Masukkan angka hari yang valid!${NC}"
    echo ""
    read -n 1 -s -r -p "Tekan apa saja untuk kembali..."
    m-zivpn
fi

# ==============================
# GENERATE EXP DATE
# ==============================
exp=$(date -d "$days days" +"%Y-%m-%d" 2>/dev/null || date -d "+$days days" +"%Y-%m-%d")

# ==============================
# SAVE USER
# ==============================
echo "$user $exp" >> "$DB"

# ==============================
# REBUILD CONFIG
# ==============================
if [ -f /root/AutoscriptXRAY/udp/rebuild-config.sh ]; then
    bash /root/AutoscriptXRAY/udp/rebuild-config.sh
fi

# ==============================
# GET DOMAIN
# ==============================
DOMAIN=$(cat /etc/xray/domain 2>/dev/null)

if [[ -z "$DOMAIN" ]]; then
    DOMAIN=$(curl -s --max-time 5 ipv4.icanhazip.com || curl -s --max-time 5 ifconfig.me)
fi

clear

# ==============================
# OUTPUT
# ==============================
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[44;1;39m       ZIVPN ACCOUNT CREATED       \E[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

printf " ${WHITE}Username${NC}    : %s\n" "$user"
printf " ${WHITE}Expired On${NC}  : %s\n" "$exp"
printf " ${WHITE}Host/IP${NC}     : %s\n" "$DOMAIN"
printf " ${WHITE}UDP Port${NC}    : 5667\n"
printf " ${WHITE}Password${NC}    : %s\n" "$user"
printf " ${WHITE}Protocol${NC}    : UDP\n"
printf " ${WHITE}OBFS${NC}        : zivpn\n"

echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "${YELLOW}📱 ZIVPN CLIENT CONFIG${NC}"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e " Host      : ${DOMAIN}"
echo -e " Password  : ${user}"
echo -e " UDP Mode  : ON"
echo -e " TLS       : ON"
echo -e " OBFS      : zivpn"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

echo ""
read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."

# Kembali ke menu ZIVPN
m-zivpn

