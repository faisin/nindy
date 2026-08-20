#!/bin/bash
# Cek login SS WS - by znandev

clear
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[44;1;39m       Check SS WS Online User     \E[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

log_file="/var/log/xray/access.log"

if [[ ! -f $log_file ]]; then
    echo ""
    echo -e "\033[1;31m❌ Log file tidak ditemukan!\033[0m"
    echo ""
    read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."
    menu
fi

echo -e "\n\033[1;32m🔍 Daftar IP & User yang sedang aktif terhubung (SS WS):\033[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

# Menampilkan statistik koneksi aktif dari log xray
# Menggunakan filter email/user jika tersedia atau menampilkan IP dan koneksi unik
active_connections=$(grep -E "ssws|accepted" "$log_file" 2>/dev/null | tail -n 200)

if [[ -z "$active_connections" ]]; then
    echo -e " \033[1;33mTidak ada aktivitas koneksi saat ini.\033[0m"
else
    # Meringkas IP unik yang terhubung
    grep 'accepted' "$log_file" | awk '{print $3}' | cut -d':' -f1 | sort | uniq -c | sort -nr | while read -r count ip; do
        echo -e " IP : \033[1;36m$ip\033[0m | Total Koneksi : \033[1;32m$count\033[0m"
    done
fi

echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""

read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."

# Kembali ke menu utama
menu

