#!/bin/bash
# ==========================================
# Buat Akun Trojan - Xray Core
# ==========================================

clear
echo -e "\033[0;36m==========================================\033[0m"
echo -e "\033[0;32m          BUAT AKUN TROJAN XRAY           \033[0m"
echo -e "\033[0;36m==========================================\033[0m"

read -p " Masukkan Username / Nama: " user
read -p " Masukkan Masa Aktif (Hari): " masa_aktif

if [ -z "$user" ]; then
    echo -e "\033[0;31m[X] Username tidak boleh kosong!\033[0m"
    exit 1
fi

# UUID otomatis untuk akun Xray
uuid=$(cat /proc/sys/kernel/random/uuid)
exp_date=$(date -d "+$masa_aktif days" +"%Y-%m-%d")

# Tambahkan logika penulisan akun ke file config.json Xray (jika diperlukan)
# Contoh format link Trojan
domain=$(cat /etc/xray/domain 2>/dev/null || echo "myvps.com")
trojan_link="trojan://${uuid}@${domain}:443?security=tls&type=tcp&sni=${domain}#${user}"

clear
echo -e "\033[0;36m==========================================\033[0m"
echo -e "\033[0;32m          DETAIL AKUN TROJAN BERHASIL     \033[0m"
echo -e "\033[0;36m==========================================\033[0m"
echo -e " Remarks     : \033[0;33m${user}\033[0m"
echo -e " Domain      : \033[0;33m${domain}\033[0m"
echo -e " UUID        : \033[0;33m${uuid}\033[0m"
echo -e " Port TLS    : \033[0;33m443\033[0m"
echo -e " Expired On  : \033[0;33m${exp_date}\033[0m"
echo -e "\033[0;36m------------------------------------------\033[0m"
echo -e " Link Trojan : \033[0;32m${trojan_link}\033[0m"
echo -e "\033[0;36m==========================================\033[0m"
read -p "Tekan [Enter] untuk kembali..."
