#!/bin/bash
# ==========================================
# TRIAL ZIVPN USER - by znandev
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
echo -e "\E[44;1;39m       TRIAL ZIVPN USER            \E[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""

# Pastikan direktori database tersedia
mkdir -p /etc/zivpn
touch "$DB"

# ==============================
# GENERATE USER
# ==============================
USER="trial$(tr -dc a-z0-9 </dev/urandom 2>/dev/null | head -c4 || echo $RANDOM)"

# ==============================
# CHECK DUPLICATE
# ==============================
while grep -qw "^$USER" "$DB" 2>/dev/null; do
    USER="trial$(tr -dc a-z0-9 </dev/urandom 2>/dev/null | head -c4 || echo $RANDOM)"
done

# ==============================
# TRIAL EXPIRED (1 Hari)
# ==============================
DAYS=1
EXP=$(date -d "$DAYS days" +"%Y-%m-%d" 2>/dev/null || date -d "+$DAYS day" +"%Y-%m-%d")

# ==============================
# SAVE USER
# ==============================
echo "$USER $EXP" >> "$DB"

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
echo -e "\E[44;1;39m      TRIAL ZIVPN ACCOUNT          \E[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

printf " ${WHITE}Username${NC}    : %s\n" "$USER"
printf " ${WHITE}Password${NC}    : %s\n" "$USER"
printf " ${WHITE}Host/IP${NC}     : %s\n" "$DOMAIN"
printf " ${WHITE}UDP Port${NC}    : 5667\n"
printf " ${WHITE}Protocol${NC}    : UDP\n"
printf " ${WHITE}OBFS${NC}        : zivpn\n"
printf " ${WHITE}Expired On${NC}  : %s\n" "$EXP"

echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "${YELLOW}📱 ZIVPN CLIENT CONFIG${NC}"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e " Host      : ${DOMAIN}"
echo -e " Password  : ${USER}"
echo -e " UDP Mode  : ON"
echo -e " TLS       : ON"
echo -e " OBFS      : zivpn"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

echo ""
read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."

# Kembali ke menu ZIVPN
m-zivpn

