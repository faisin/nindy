#!/bin/bash
# ==========================================
# DELETE ZIVPN USER - by znandev
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
echo -e "\E[44;1;39m       DELETE ZIVPN USER           \E[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""

# ==============================
# CHECK EMPTY DB
# ==============================
if [[ ! -f $DB ]] || [[ ! -s $DB ]]; then
    echo -e "${RED}❌ No ZIVPN users found!${NC}"
    echo ""
    echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo ""
    read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."
    m-zivpn
fi

# ==============================
# SHOW USER LIST
# ==============================
printf "${WHITE} %-4s %-18s %-15s${NC}\n" \
"NO" "USERNAME" "EXPIRED"

echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

NO=1

while read -r user exp; do

    [[ -z "$user" ]] && continue

    printf " %-4s %-18s %-15s\n" \
    "$NO" "$user" "$exp"

    ((NO++))

done < "$DB"

echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

# ==============================
# INPUT USER & VALIDATION
# ==============================
echo ""
until [[ $user =~ ^[a-zA-Z0-9_]+$ ]]; do
    read -rp "Input Username : " user
done

# ==============================
# CHECK USER
# ==============================
if ! grep -wq "^$user" "$DB"; then
    echo -e "\n${RED}❌ User not found!${NC}"
    echo ""
    read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."
    m-zivpn
fi

# ==============================
# DELETE USER
# ==============================
sed -i "/^$user /d" "$DB"

# ==============================
# REBUILD CONFIG
# ==============================
if [ -f /root/AutoscriptXRAY/udp/rebuild-config.sh ]; then
    bash /root/AutoscriptXRAY/udp/rebuild-config.sh
fi

clear

# ==============================
# SUCCESS OUTPUT
# ==============================
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[44;1;39m       DELETE ZIVPN SUCCESS        \E[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

echo ""
echo -e " ${WHITE}Username${NC} : $user"
echo -e " ${WHITE}Status${NC}   : Deleted Successfully"
echo ""

echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

echo ""
read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."

# Kembali ke menu ZIVPN
m-zivpn

