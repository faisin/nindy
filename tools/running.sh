#!/bin/bash
# ==========================================
# Cek Status Layanan & Port Aktif
# ==========================================

clear
echo -e "\033[0;36m==========================================\033[0m"
echo -e "\033[0;32m         STATUS LAYANAN & PORT VPS        \033[0m"
echo -e "\033[0;36m==========================================\033[0m"

# Cek Xray Service
if systemctl is-active --quiet xray; then
    echo -e " Xray Core : \033[0;32m[RUNNING]\033[0m"
else
    echo -e " Xray Core : \033[0;31m[STOPPED]\033[0m"
fi

# Cek Dropbear Service
if systemctl is-active --quiet dropbear; then
    echo -e " Dropbear  : \033[0;32m[RUNNING]\033[0m"
else
    echo -e " Dropbear  : \033[0;31m[STOPPED]\033[0m"
fi

# Cek Nginx Service
if systemctl is-active --quiet nginx; then
    echo -e " Nginx     : \033[0;32m[RUNNING]\033[0m"
else
    echo -e " Nginx     : \033[0;31m[STOPPED]\033[0m"
fi

echo -e "\033[0;36m------------------------------------------\033[0m"
echo -e "\033[0;33mDaftar Port Aktif di Sistem:\033[0m"
netstat -nutlp | grep LISTEN

echo -e "\033[0;36m==========================================\033[0m"
read -p "Tekan [Enter] untuk kembali ke menu..."
