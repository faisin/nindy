#!/bin/bash
# ==========================================
# Master Installer - Nindy VPS
# ==========================================

# Panggil helper
source ./tools/helper.sh

root_check
print_banner

echo -e "${YELLOW}[+] Memulai instalasi komponen sistem Nindy...${NC}"
sleep 2

# 1. Install Tools & Dependensi Dasar
if [ -f "./install/nginx.sh" ]; then
    echo -e "${BLUE}[*] Menginstal Nginx & Tools...${NC}"
    bash ./install/nginx.sh
fi

# 2. Install SSH & Dropbear
if [ -f "./install/ssh.sh" ]; then
    echo -e "${BLUE}[*] Mengonfigurasi SSH & Dropbear...${NC}"
    bash ./install/ssh.sh
fi

# 3. Install Xray Core (Trojan, Vless, Vmess)
if [ -f "./install/xray.sh" ]; then
    echo -e "${BLUE}[*] Menginstal Xray Core...${NC}"
    bash ./install/xray.sh
fi

# 4. Install WebSocket (SSHWS & Go Proxy)
if [ -f "./install/sshws.sh" ]; then
    echo -e "${BLUE}[*] Mengonfigurasi SSH Websocket...${NC}"
    bash ./install/sshws.sh
fi

# 5. Install UDP Custom / Zivpn
if [ -f "./install/zivpn.sh" ]; then
    echo -e "${BLUE}[*] Menginstal layanan Zivpn / UDP...${NC}"
    bash ./install/zivpn.sh
fi

# Berikan izin eksekusi pada menu utama
chmod +x menu.sh

echo -e "${CYAN}==========================================${NC}"
echo -e "${GREEN}[✓] INSTALASI SEPENUHNYA SELESAI!${NC}"
echo -e "${YELLOW}Ketik '${CYAN}./menu.sh${YELLOW}' atau '${CYAN}menu${YELLOW}' untuk membuka panel.${NC}"
echo -e "${CYAN}==========================================${NC}"
