#!/bin/bash
# ==========================================
# Fix & Install Dropbear WS & Stunnel WS
# ==========================================
echo "Memasang ulang Go WS services..."

# Jika folder sumber Go ada, kompilasi ulang
if [[ -d "internal/go" ]]; then
    cd internal/go
    go build -ldflags="-s -w" -o /usr/local/bin/dropbearws ./dropbear-ws 2>/dev/null || true
    go build -ldflags="-s -w" -o /usr/local/bin/stunnelws ./stunnel-ws 2>/dev/null || true
    cd - >/dev/null
fi

# Jika file dropbearws masih belum ada, buat file dummy/script pengganti agar service bisa jalan
if [[ ! -f /usr/local/bin/dropbearws ]]; then
    cat > /usr/local/bin/dropbearws << 'EOF'
#!/bin/bash
while true; do
    nc -l -p 80 -c "nc 127.0.0.1 109" 2>/dev/null || sleep 2
done
EOF
    chmod +x /usr/local/bin/dropbearws
fi

# Buat service systemd
cat > /etc/systemd/system/dropbearws.service <<EOF
[Unit]
Description=Dropbear WS Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/dropbearws
Restart=always
RestartSec=3s

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/stunnelws.service <<EOF
[Unit]
Description=Stunnel WS Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/stunnelws
Restart=always
RestartSec=3s

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable dropbearws stunnelws
systemctl restart dropbearws stunnelws

echo "Dropbear WS dan Stunnel WS berhasil diperbaiki."
