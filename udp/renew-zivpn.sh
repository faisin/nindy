#!/bin/bash
# ==========================================
# RENEW ZIVPN USER - by znandev
# ==========================================
set -e

DB="/etc/zivpn/users.db"
TEMP="/tmp/zivpn-renew.tmp"

clear

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m'

echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[44;1;39m       RENEW ZIVPN USER            \E[0m"
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
# HEADER
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
if ! grep -wq "^$user " "$DB"; then
    echo -e "\n${RED}❌ User not found!${NC}"
    echo ""
    read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."
    m-zivpn
fi

# ==============================
# INPUT RENEW DAYS
# ==============================
read -rp "Extend Days   : " days

if ! [[ "$days" =~ ^[0-9]+$ ]]; then
    echo -e "\n${RED}❌ Masukkan angka hari yang valid!${NC}"
    echo ""
    read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."
    m-zivpn
fi

# ==============================
# GET OLD EXP DATE
# ==============================
old_exp=$(grep "^$user " "$DB" | awk '{print $2}')

# ==============================
# CALCULATE NEW EXP
# ==============================
today=$(date +%s)
old_exp_ts=$(date -d "$old_exp" +%s 2>/dev/null || date +%s)

if [[ $old_exp_ts -lt $today ]]; then
    new_exp=$(date -d "+$days days" +"%Y-%m-%d")
else
    new_exp=$(date -d "$old_exp +$days days" +"%Y-%m-%d")
fi

# ==============================
# UPDATE DB
# ==============================
awk -v user="$user" -v exp="$new_exp" '
{
    if ($1 == user) {
        print $1, exp
    } else {
        print
    }
}
' "$DB" > "$TEMP"

mv "$TEMP" "$DB"

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
echo -e "\E[44;1;39m       RENEW ZIVPN SUCCESS         \E[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

echo ""
echo -e " ${WHITE}Username${NC}     : $user"
echo -e " ${WHITE}Old Expired${NC} : $old_exp"
echo -e " ${WHITE}New Expired${NC} : $new_exp"
echo -e " ${WHITE}Extended${NC}    : $days Days"
echo ""

echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

echo ""
read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."

# Kembali ke menu ZIVPN
m-zivpn

