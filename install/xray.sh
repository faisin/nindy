#!/bin/bash
# ==========================================
# Installer Modul Xray Core (Trojan/Vless/Vmess)
# ==========================================

echo -e "\033[0;34m[*] Memulai instalasi Xray Core...\033[0m"

# Buat direktori konfigurasi Xray jika belum ada
mkdir -p /etc/xray
mkdir -p /var/log/xray

# Unduh dan instal Xray core resmi menggunakan skrip resmi XTLS
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# Salin file konfigurasi dasar jika tersedia di folder config
if [ -f "./config/xray.json" ]; then
    cp ./config/xray.json /etc/xray/config.json
fi

# Aktifkan dan jalankan service Xray
systemctl daemon-reload
systemctl enable xray
systemctl restart xray

echo -e "\033[0;32m[✓] Xray Core berhasil diinstal dan diaktifkan!\033[0m"
