#!/bin/bash
# ==========================================
# MONITOR ONLINE ZIVPN USER - by znandev
# ==========================================

clear

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m'

LOG_FILE="/tmp/zivpn-monitor.log"

echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[44;1;39m       ONLINE ZIVPN USERS          \E[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""

# ==============================
# CHECK SERVICE
# ==============================
if ! systemctl is-active --quiet zivpn; then
    echo -e "${RED}❌ ZIVPN service is not running!${NC}"
    echo ""
    echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo ""
    read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."
    m-zivpn
fi

# ==============================
# GET CONNECTION
# ==============================
ss -unap 2>/dev/null | grep "zivpn" | \
awk '{print $5}' | \
cut -d':' -f1 | \
sort -u > "$LOG_FILE"

TOTAL=$(cat "$LOG_FILE" 2>/dev/null | wc -l)

# ==============================
# NO CONNECTION
# ==============================
if [[ $TOTAL -eq 0 ]]; then
    echo -e "${YELLOW}⚠️ No online ZIVPN users!${NC}"
    echo ""
    echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    rm -f "$LOG_FILE"
    echo ""
    read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."
    m-zivpn
fi

# ==============================
# HEADER
# ==============================
printf "${WHITE} %-4s %-25s${NC}\n" \
"NO" "IP ADDRESS"

echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

# ==============================
# SHOW ONLINE IP
# ==============================
NO=1

while read -r ip; do

    [[ -z "$ip" ]] && continue

    printf " %-4s %-25s\n" \
    "$NO" "$ip"

    ((NO++))

done < "$LOG_FILE"

echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

echo -e "${WHITE}Total Online${NC} : $TOTAL"

echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

rm -f "$LOG_FILE"

echo ""
read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."

# Kembali ke menu ZIVPN
m-zivpn

