#!/bin/bash
# Perpanjang akun SS WS - by znandev
set -e

clear
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[44;1;39m    Renew Shadowsocks Account    \E[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""

db_file="/etc/xray/ssws.db"

if [ ! -f "$db_file" ] || [ ! -s "$db_file" ]; then
    echo -e "\033[1;31m❌ Database user Shadowsocks tidak ditemukan atau kosong!\033[0m"
    echo ""
    read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."
    menu
fi

read -rp "Masukkan username yang ingin diperpanjang: " user

# Cek apakah user ada di ssws.db
if ! grep -q "^$user " "$db_file"; then
    echo -e "\n\033[1;31m❌ Username '$user' tidak ditemukan di database!\033[0m"
    echo ""
    read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."
    menu
fi

read -rp "Tambah masa aktif (hari): " tambah

# Validasi input angka masa aktif
if ! [[ "$tambah" =~ ^[0-9]+$ ]]; then
    echo -e "\n\033[1;31m❌ Masukkan angka hari yang valid!\033[0m"
    echo ""
    read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."
    menu
fi

# Ambil data lama dari database (format: user exp_date uuid)
old_data=$(grep -w "^$user" "$db_file")
exp_now=$(echo "$old_data" | awk '{print $2}')
uuid=$(echo "$old_data" | awk '{print $3}')

# Hitung tanggal expired baru
exp_ts=$(date -d "$exp_now" +%s 2>/dev/null || date +%s)
now_ts=$(date +%s)

if [ $exp_ts -ge $now_ts ]; then
    remain_days=$(( (exp_ts - now_ts) / 86400 ))
else
    remain_days=0
fi

total_days=$(( remain_days + tambah ))
new_exp=$(date -d "$tambah days" +%Y-%m-%d 2>/dev/null || date -d "+$tambah day" +%Y-%m-%d)

# Jika akun sudah expired, dihitung dari hari ini
if [ $exp_ts -lt $now_ts ]; then
    new_exp=$(date -d "+$tambah days" +%Y-%m-%d)
else
    new_exp=$(date -d "$exp_now + $tambah days" +%Y-%m-%d)
fi

# Update database ssws.db
grep -v "^$user " "$db_file" > "${db_file}.tmp"
echo "${user} ${new_exp} ${uuid}" >> "${db_file}.tmp"
mv "${db_file}.tmp" "$db_file"

echo -e "\n\033[1;32m✅ Masa aktif akun '$user' berhasil diperpanjang hingga $new_exp\033[0m"
echo ""

read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."

# Kembali ke menu utama
menu

