#!/bin/bash
# Hapus akun WireGuard - by znandev
set -e

clear
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[44;1;39m      Delete WireGuard Account     \E[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""

[[ -f /etc/wireguard/wg0.conf ]] || {
    echo -e "\033[1;31m❌ WireGuard is not installed!\033[0m"
    echo ""
    read -n 1 -s -r -p "Tekan apa saja untuk kembali..."
    m-wg
}

# Input username dengan validasi
until [[ $user =~ ^[a-zA-Z0-9_-]+$ ]]; do
    read -rp "Masukkan nama user yang ingin dihapus: " user
done

pubkey=$(grep -A 3 "# $user" /etc/wireguard/wg0.conf 2>/dev/null | grep PublicKey | awk '{print $3}')

if [[ -z "$pubkey" ]]; then
    echo -e "\n\033[1;31m❌ User '$user' tidak ditemukan!\033[0m"
    echo ""
    read -n 1 -s -r -p "Tekan apa saja untuk kembali..."
    m-wg
fi

# Hapus dari config server
sed -i "/# $user/,+4d" /etc/wireguard/wg0.conf

# Hapus file konfigurasi klien dan QR code jika ada
rm -f "/etc/wireguard/clients/$user.conf"
rm -f "/etc/wireguard/clients/$user.png"

# Restart layanan WireGuard
systemctl restart wg-quick@wg0

echo -e "\n\033[1;32m✅ Akun WireGuard '$user' berhasil dihapus!\033[0m"
echo ""

read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."

# Kembali ke menu WireGuard
m-wg

