#!/bin/bash
# ==========================================
# Skrip Uninstaller Total - Nindy VPS
# ==========================================

clear
echo -e "\033[0;31m==========================================\033[0m"
echo -e "\033[0;31m          PERINGATAN UNINSTALL TOTAL      \033[0m"
echo -e "\033[0;31m==========================================\033[0m"
echo -e "Skrip ini akan menghapus seluruh layanan Xray,"
echo -e "Dropbear, WebSocket, dan konfigurasi Nindy!"
echo -e "\033[0;31m==========================================\033[0m"
read -p "Apakah Anda yakin ingin melanjutkan? (y/n): " confirm

if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
    echo -e "\033[0;33m[*] Menghentikan dan menghapus layanan...\033[0m"
    
    systemctl stop xray dropbear ws-dropbear ws-stunnel udp-custom > /dev/null 2>&1
    systemctl disable xray dropbear ws-dropbear ws-stunnel udp-custom > /dev/null 2>&1
    
    rm -rf /etc/xray /etc/zivpn /etc/systemd/system/ws-*.service /etc/systemd/system/udp-custom.service
    
    echo -e "\033[0;32m[✓] VPS berhasil dibersihkan dari seluruh komponen Nindy.\033[0m"
else
    echo -e "\033[0;34m[!] Proses uninstall dibatalkan.\033[0m"
fi
