#!/bin/bash
# ==========================================
# CHECK ZIVPN USER - by znandev
# ==========================================

DB="/etc/zivpn/users.db"

clear

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m'

echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[44;1;39m          ZIVPN MEMBER LIST        \E[0m"
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
printf "${WHITE} %-4s %-18s %-15s %-10s${NC}\n" \
"NO" "USERNAME" "EXPIRED" "STATUS"

echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

# ==============================
# READ USER DB
# ==============================
NO=1

while read -r user exp; do

    # Skip empty line
    [[ -z "$user" ]] && continue

    # Expired check
    exp_ts=$(date -d "$exp" +%s 2>/dev/null || date +%s)
    now_ts=$(date +%s)

    if [[ $now_ts -gt $exp_ts ]]; then
        STATUS="${RED}EXPIRED${NC}"
    else
        STATUS="${GREEN}ACTIVE${NC}"
    fi

    printf " %-4s %-18s %-15s %-10b\n" \
    "$NO" "$user" "$exp" "$STATUS"

    ((NO++))

done < "$DB"

echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

TOTAL=$(grep -vc '^$' "$DB" 2>/dev/null || echo 0)

echo -e "${WHITE}Total Users${NC} : $TOTAL"

echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

echo ""
read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."

# Kembali ke menu ZIVPN
m-zivpn

