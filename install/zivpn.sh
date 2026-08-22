#!/bin/bash
# ==========================================
# Installer Modul UDP Zivpn / UDP Custom
# ==========================================

echo -e "\033[0;34m[*] Menginstal dan mengonfigurasi layanan UDP Zivpn...\033[0m"

# Buat direktori konfigurasi UDP jika belum ada
mkdir -p /etc/zivpn

# Salin konfigurasi atau buat service dasar jika file pendukung tersedia
if [ -f "./sshws/udp-custom.service" ]; then
    cp ./sshws/udp-custom.service /etc/systemd/system/
    systemctl daemon-reload
    systemctl enable udp-custom.service
    systemctl start udp-custom.service
fi

echo -e "\033[0;32m[✓] Layanan UDP Zivpn berhasil dikonfigurasi!\033[0m"
