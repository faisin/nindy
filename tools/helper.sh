#!/bin/bash
# ==========================================
# Color Codes & Helper Functions for Nindy VPS
# ==========================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Fungsi Cek Akses Root
function root_check() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}[X] Error: Script ini harus dijalankan sebagai user root!${NC}"
        exit 1
    fi
}

# Fungsi Banner / Header Tampilan
function print_banner() {
    clear
    echo -e "${CYAN}==========================================${NC}"
    echo -e "${GREEN}          NINDY VPS MANAGEMENT SYSTEM      ${NC}"
    echo -e "${CYAN}==========================================${NC}"
}
