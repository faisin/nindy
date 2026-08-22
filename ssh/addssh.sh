#!/bin/bash
# ==========================================
# Buat Akun SSH & Dropbear Baru
# ==========================================

clear
echo -e "\033[0;36m==========================================\033[0m"
echo -e "\033[0;32m          BUAT AKUN SSH / DROPBEAR        \033[0m"
echo -e "\033[0;36m==========================================\033[0m"

read -p " Masukkan Username SSH : " username
read -p " Masukkan Password     : " password
read -p " Masukkan Masa Aktif (Hari) : " masa_aktif

if [ -z "$username" ] || [ -z "$password" ]; then
    echo -e "\033[0;31m[X] Username dan password tidak boleh kosong!\033[0m"
    exit 1
fi

# Hitung tanggal expired
exp_date=$(date -d "+$masa_aktif days" +"%Y-%m-%d")

# Tambahkan user sistem Linux
useradd -e "$exp_date" -s /bin/false -M "$username"
echo -e "$password\n$password" | passwd "$username" > /dev/null 2>&1

# Ambil IP VPS
ip_vps=$(curl -s ifconfig.me)

clear
echo -e "\033[0;36m==========================================\033[0m"
echo -e "\033[0;32m         AKUN SSH BERHASIL DIBUAT         \033[0m"
echo -e "\033[0;36m==========================================\033[0m"
echo -e " Host / IP   : \033[0;33m${ip_vps}\033[0m"
echo -e " Username    : \033[0;33m${username}\033[0m"
echo -e " Password    : \033[0;33m${password}\033[0m"
echo -e " Port SSH    : \033[0;33m22, 109\033[0m"
echo -e " Port Dropbear: \033[0;33m443\033[0m"
echo -e " Expired On  : \033[0;33m${exp_date}\033[0m"
echo -e "\033[0;36m==========================================\033[0m"
read -p "Tekan [Enter] untuk kembali..."
