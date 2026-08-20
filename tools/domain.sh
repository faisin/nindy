#!/bin/bash
# Atur ulang domain - by znandev
set -e

# Warna
CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

clear
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[44;1;39m         GANTI DOMAIN XRAY         \E[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""

# Pastikan direktori xray tersedia
mkdir -p /etc/xray

# Minta domain baru dengan validasi
until [[ $new_domain =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; do
    read -rp "📌 Masukkan domain baru (contoh: domain.com): " new_domain
done

# Simpan domain baru ke file
echo "$new_domain" > /etc/xray/domain

# Restart service terkait jika ada
echo -e "\n🔄 Menerapkan perubahan domain..."
systemctl restart xray 2>/dev/null || true
systemctl restart zivpn 2>/dev/null || true

clear
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[44;1;39m       DOMAIN BERHASIL DIGANTI     \E[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\n${GREEN}✅ Domain berhasil diperbarui!${NC}"
echo -e "🌐 Domain baru: ${CYAN}$new_domain${NC}"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""

read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."

# Kembali ke menu utama
menu

