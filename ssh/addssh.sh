#!/bin/bash
# ==========================================
# CREATE SSH ACCOUNT - by znandev
# ==========================================
set -e

DOMAIN=$(cat /etc/xray/domain 2>/dev/null)
IP=$(curl -s --max-time 5 ipv4.icanhazip.com || curl -s --max-time 5 ifconfig.me)

if [[ -z "$DOMAIN" ]]; then
    DOMAIN="$IP"
fi

clear

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m'

echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[44;1;39m         CREATE SSH ACCOUNT        \E[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""

# ==============================
# INPUT USER & VALIDATION
# ==============================
until [[ $user =~ ^[a-zA-Z0-9_]+$ ]]; do
    read -rp "Username      : " user
done

# Check existing user
if id "$user" &>/dev/null || grep -qw "^$user" /etc/passwd; then
    echo -e "\n${RED}❌ User already exists!${NC}"
    echo ""
    read -n 1 -s -r -p "Tekan apa saja untuk kembali..."
    [ -f /usr/bin/m-ssh ] && m-ssh || menu
fi

read -s -p "Password      : " pass
echo ""

if [[ -z "$pass" ]]; then
    echo -e "\n${RED}❌ Password tidak boleh kosong!${NC}"
    echo ""
    read -n 1 -s -r -p "Tekan apa saja untuk kembali..."
    [ -f /usr/bin/m-ssh ] && m-ssh || menu
fi

read -rp "Expired Days  : " days

if ! [[ "$days" =~ ^[0-9]+$ ]]; then
    echo -e "\n${RED}❌ Invalid expiration days!${NC}"
    echo ""
    read -n 1 -s -r -p "Tekan apa saja untuk kembali..."
    [ -f /usr/bin/m-ssh ] && m-ssh || menu
fi

# Generate Exp Date (kompatibel dengan berbagai versi date)
EXP=$(date -d "$days days" +%Y-%m-%d 2>/dev/null || date -d "+$days days" +%Y-%m-%d 2>/dev/null)

# ==============================
# CREATE USER SYSTEM
# ==============================
useradd -e "$EXP" -m -s /bin/bash "$user" >/dev/null 2>&1 || {
    echo -e "\n${RED}❌ Failed to create system user!${NC}"
    exit 1
}

echo "$user:$pass" | chpasswd >/dev/null 2>&1 || {
    echo -e "\n${RED}❌ Failed to set password!${NC}"
    exit 1
}

mkdir -p /root/accounts
ACCOUNT_FILE="/root/accounts/${user}.txt"

cat > "$ACCOUNT_FILE" <<EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SSH ACCOUNT DETAILS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Username : $user
Password : $pass
Expired  : $EXP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Domain   : $DOMAIN
IP VPS   : $IP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
OpenSSH  : 22
Dropbear : 109, 143
SSH WS   : 2082
SSH WSS  : 2096
UdpSSH   : 1-65535
BadVPN   : 7300
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SSH UDP CUSTOM:
$DOMAIN:1-65535@$user:$pass
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SSH WS:
$DOMAIN:2082@$user:$pass
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SSH WSS:
$DOMAIN:2096@$user:$pass
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Payload WS:
GET / HTTP/1.1[crlf]
Host: $DOMAIN[crlf]
Upgrade: websocket[crlf]
Connection: Upgrade[crlf]
[crlf]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF

clear

# ==============================
# OUTPUT
# ==============================
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[44;1;39m       SSH ACCOUNT CREATED         \E[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

printf " ${WHITE}Username${NC}       : %s\n" "$user"
printf " ${WHITE}Password${NC}       : %s\n" "$pass"
printf " ${WHITE}Expired${NC}        : %s\n" "$EXP"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
printf " ${WHITE}Domain${NC}         : %s\n" "$DOMAIN"
printf " ${WHITE}IP VPS${NC}         : %s\n" "$IP"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
printf " ${WHITE}OpenSSH${NC}        : 22\n"
printf " ${WHITE}Dropbear${NC}       : 109, 143\n"
printf " ${WHITE}SSH WS${NC}         : 2082\n"
printf " ${WHITE}SSH WSS${NC}        : 2096\n"
printf " ${WHITE}UdpSSH${NC}         : 1-65535\n"
printf " ${WHITE}BadVPN UDPGW${NC}   : 7300\n"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "${YELLOW}📱 CLIENT FORMATS${NC}"
echo -e " UDP Custom : $DOMAIN:1-65535@$user:$pass"
echo -e " SSH WS     : $DOMAIN:2082@$user:$pass"
echo -e " SSH WSS    : $DOMAIN:2096@$user:$pass"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e " Saved to   : ${CYAN}$ACCOUNT_FILE${NC}"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

echo ""
read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."

# Kembali ke menu SSH atau Menu Utama
if [ -f /usr/bin/m-ssh ]; then
    m-ssh
else
    menu
fi

