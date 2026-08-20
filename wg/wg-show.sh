#!/bin/bash
# Lihat daftar akun aktif WireGuard - by znandev

clear
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[44;1;39m      WireGuard Active Accounts    \E[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""

if [[ ! -f /etc/wireguard/wg0.conf ]]; then
    echo -e "\033[1;31m❌ WireGuard tidak terinstall atau file config tidak ditemukan!\033[0m"
    echo ""
    read -n 1 -s -r -p "Tekan apa saja untuk kembali..."
    m-wg
fi

echo -e "\033[1;32m🔍 Status & Peer Terhubung (WireGuard):\033[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

if ! systemctl is-active --quiet wg-quick@wg0; then
    echo -e "\033[1;33m⚠️ Layanan WireGuard sedang tidak aktif.\033[0m"
else
    wg show wg0
fi

echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""

read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."

# Kembali ke menu WireGuard
m-wg

