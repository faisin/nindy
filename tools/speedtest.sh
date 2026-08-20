#!/bin/bash
# Speedtest CLI - by znandev
set -e

# Warna
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

clear
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[44;1;39m         SPEEDTEST VPS             \E[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""

# Cek apakah speedtest (Ookla atau speedtest-cli) terinstall
if ! command -v speedtest &> /dev/null && ! command -v speedtest-cli &> /dev/null; then
    echo -e "${YELLOW}⚠️ speedtest belum terinstall, sedang menginstal...${NC}"
    apt-get update -y >/dev/null 2>&1 || true
    apt-get install speedtest-cli -y >/dev/null 2>&1 || true
fi

echo -e "${CYAN}📡 Sedang menguji kecepatan koneksi VPS... Mohon tunggu...${NC}"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""

# Jalankan speedtest
if command -v speedtest &> /dev/null; then
    speedtest --share || speedtest
elif command -v speedtest-cli &> /dev/null; then
    speedtest-cli --simple
else
    echo -e "${RED}❌ Gagal menginstal alat speedtest!${NC}"
fi

echo ""
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "${GREEN}✔️ Uji kecepatan selesai!${NC}"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""

read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu utama..."

# Kembali ke menu utama
menu

