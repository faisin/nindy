#!/bin/bash
# ==========================================
# Installer Modul SSH Websocket & Go Proxy
# ==========================================

echo -e "\033[0;34m[*] Mengonfigurasi Layanan WebSocket & Go Proxy...\033[0m"

# Pindahkan file service Python Websocket jika ada di folder sshws/
if [ -f "./sshws/ws-dropbear.service" ]; then
    cp ./sshws/ws-dropbear.service /etc/systemd/system/
    cp ./sshws/ws-stunnel.service /etc/systemd/system/
fi

# Pindahkan file service Go Proxy jika ada di folder internal/go/
if [ -f "./internal/go/dropbear-ws.service" ]; then
    cp ./internal/go/dropbear-ws.service /etc/systemd/system/
    cp ./internal/go/stunnel-ws.service /etc/systemd/system/
fi

# Reload systemd dan aktifkan semua layanan websocket
systemctl daemon-reload
systemctl enable ws-dropbear.service
systemctl enable ws-stunnel.service
systemctl start ws-dropbear.service
systemctl start ws-stunnel.service

echo -e "\033[0;32m[✓] Layanan WebSocket berhasil diinstal dan diaktifkan!\033[0m"
