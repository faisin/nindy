#!/bin/bash
source ./tools/helper.sh

while true; do
    print_banner
    echo -e " [1] ${GREEN}Menu Akun SSH & Dropbear${NC}"
    echo -e " [2] ${GREEN}Menu Xray (Trojan / Vless / Vmess)${NC}"
    echo -e " [3] ${GREEN}Menu UDP / Zivpn${NC}"
    echo -e " [4] ${GREEN}Menu Wireguard${NC}"
    echo -e " [5] ${GREEN}Menu Tools & Backup${NC}"
    echo -e " [x] ${RED}Keluar (Exit)${NC}"
    echo -e "${CYAN}==========================================${NC}"
    read -p " Silakan pilih menu [1-5 atau x]: " choice

    case $choice in
        1) 
            if [ -f "./ssh/m-ssh" ]; then
                bash ./ssh/m-ssh
            else
                echo -e "${RED}[X] File m-ssh tidak ditemukan!${NC}"; sleep 1
            fi
            ;;
        2) 
            # Contoh masuk ke manajemen x-ray trojan/vmess
            clear
            echo -e "${YELLOW}=== MANAJEMEN XRAY ===${NC}"
            echo -e " [1] Buat Akun Trojan"
            echo -e " [2] Buat Akun Vmess"
            read -p " Pilih: " xray_opt
            if [ "$xray_opt" = "1" ]; then
                bash ./xray/add-trojan.sh
            elif [ "$xray_opt" = "2" ]; then
                bash ./xray/add-vmess.sh
            fi
            ;;
        3) 
            if [ -f "./udp/m-zivpn" ]; then
                bash ./udp/m-zivpn
            else
                bash ./udp/trial-zivpn.sh
            fi
            ;;
        4) 
            if [ -f "./wg/m-wg" ]; then
                bash ./wg/m-wg
            fi
            ;;
        5) 
            if [ -f "./tools/tools-menu" ]; then
                bash ./tools/tools-menu
            else
                bash ./tools/running.sh
            fi
            ;;
        x|X) 
            echo -e "${GREEN}Terima kasih telah menggunakan script Nindy!${NC}"
            exit 0 
            ;;
        *) 
            echo -e "${RED}Pilihan tidak valid!${NC}"
            sleep 1 
            ;;
    esac
done
