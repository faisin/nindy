#!/bin/bash
# Submenu Status Service - by znandev

# Warna
NC='\033[0m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
RED='\033[1;31m'

clear
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[44;1;39m       STATUS LAYANAN AKTIF        \E[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""

# Daftar layanan yang dicek
services=(
  "ssh"
  "dropbear"
  "sshws"
  "xray"
  "stunnel4"
  "wg-quick@wg0"
  "zivpn"
  "nginx"
)

for svc in "${services[@]}"; do
  if systemctl list-unit-files | grep -q "^${svc}\.service" || systemctl list-unit-files | grep -q "^${svc}@"; then
    status=$(systemctl is-active "$svc" 2>/dev/null)
    if [[ "$status" == "active" ]]; then
      status_colored="${GREEN}ONLINE${NC}"
    else
      status_colored="${RED}OFFLINE${NC}"
    fi
    printf " %-15s : %b\n" "$svc" "$status_colored"
  fi
done

echo ""
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""

read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu utama..."

# Kembali ke menu utama
menu

