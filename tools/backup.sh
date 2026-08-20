#!/bin/bash
# Backup tool - by znandev
set -e

# Warna
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
RED='\033[1;31m'
NC='\033[0m'

clear
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[44;1;39m      BACKUP & RESTORE TOOLS       \E[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "${GREEN}[1]${NC} Backup Data"
echo -e "${GREEN}[2]${NC} Restore Data"
echo -e "${GREEN}[x]${NC} Kembali ke menu"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
read -rp "👉 Pilih opsi: " opt

backup_folder="/root/backup-autoscript"
mkdir -p "$backup_folder"

case $opt in
    1)
        clear
        echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
        echo -e "\E[44;1;39m          MAKING BACKUP            \E[0m"
        echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
        echo -e "\n📦 Sedang membuat file backup..."
        
        # Bersihkan folder backup lama
        rm -rf "${backup_folder:?}"/*
        mkdir -p "$backup_folder/etc/xray"
        mkdir -p "$backup_folder/etc/zivpn"
        mkdir -p "$backup_folder/etc/wireguard"

        # Salin file penting
        [ -f /etc/xray/config.json ] && cp /etc/xray/config.json "$backup_folder/etc/xray/"
        [ -f /etc/xray/domain ] && cp /etc/xray/domain "$backup_folder/etc/xray/"
        [ -d /etc/xray ] && cp /etc/xray/*.db "$backup_folder/etc/xray/" 2>/dev/null || true
        [ -d /etc/zivpn ] && cp -r /etc/zivpn "$backup_folder/etc/" 2>/dev/null || true
        [ -d /etc/wireguard ] && cp -r /etc/wireguard "$backup_folder/etc/" 2>/dev/null || true

        cd /root
        if command -v zip &> /dev/null; then
            zip -r backup-autoscript.zip backup-autoscript >/dev/null
            echo -e "\n\033[1;32m✅ Backup selesai!\033[0m"
            echo -e "📁 File: /root/backup-autoscript.zip"
            echo -e "${YELLOW}Simpan file zip ini untuk restore nanti.${NC}"
        else
            echo -e "\n\033[1;31m❌ Perintah 'zip' tidak ditemukan. Gagal mengompres file.\033[0m"
        fi
        
        echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
        echo ""
        read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."
        menu
        ;;
    2)
        clear
        echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
        echo -e "\E[44;1;39m          RESTORE DATA             \E[0m"
        echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
        echo ""
        read -rp "🗂 Masukkan path file ZIP backup (contoh: /root/backup-autoscript.zip): " path
        
        if [[ -f "$path" ]]; then
            echo -e "\n🔄 Sedang merestore data..."
            unzip -o "$path" -d /root >/dev/null 2>&1
            
            if [ -d "$backup_folder" ]; then
                [ -f "$backup_folder/etc/xray/config.json" ] && cp "$backup_folder/etc/xray/config.json" /etc/xray/
                [ -f "$backup_folder/etc/xray/domain" ] && cp "$backup_folder/etc/xray/domain" /etc/xray/
                cp "$backup_folder/etc/xray/"*.db /etc/xray/ 2>/dev/null || true
                [ -d "$backup_folder/etc/zivpn" ] && cp -r "$backup_folder/etc/zivpn" /etc/
                [ -d "$backup_folder/etc/wireguard" ] && cp -r "$backup_folder/etc/wireguard" /etc/
                
                systemctl restart xray 2>/dev/null || true
                systemctl restart zivpn 2>/dev/null || true
                systemctl restart wg-quick@wg0 2>/dev/null || true
                
                echo -e "\n\033[1;32m✅ Restore selesai!\033[0m"
            else
                echo -e "\n\033[1;31m❌ Struktur folder hasil ekstrak tidak valid!\033[0m"
            fi
        else
            echo -e "\n\033[1;31m❌ File backup tidak ditemukan di path tersebut!\033[0m"
        fi
        
        echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
        echo ""
        read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."
        menu
        ;;
    x|X)
        menu
        ;;
    *)
        echo -e "\n${RED}❌ Pilihan salah!${NC}"
        sleep 1
        bash "$0"
        ;;
esac

