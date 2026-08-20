#!/usr/bin/python3
# -*- coding: utf-8 -*-
# Python SSH WebSocket Proxy - by znandev

import socket
import threading
import select
import sys
import time

LISTENING_ADDR = '0.0.0.0'

if sys.argv[1:]:
    LISTENING_PORT = sys.argv[1]
else:
    LISTENING_PORT = 2082

BUFLEN = 4096 * 4
TIMEOUT = 60
DEFAULT_HOST = '127.0.0.1:109'

RESPONSE = (
    'HTTP/1.1 101 Switching Protocols\r\n'
    'Content-Length: 104857600000\r\n'
    'Upgrade: websocket\r\n'
    'Connection: Upgrade\r\n\r\n'
)


class Server(threading.Thread):
    def __init__(self, host, port):
        super().__init__()
        self.host = host
        self.port = port
        self.running = True
        self.daemon = True

    def run(self):
        try:
            # Perbaikan: Menambahkan socket.SOCK_STREAM
            self.soc = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.soc.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            self.soc.bind((self.host, int(self.port)))
            self.soc.listen(200)
            
            while self.running:
                try:
                    c, addr = self.soc.accept()
                    ConnectionHandler(c, addr).start()
                except Exception:
                    pass
        except Exception as e:
            print(f"[!] Server Bind Error: {e}")


class ConnectionHandler(threading.Thread):
    def __init__(self, client, addr):
        super().__init__()
        self.client = client
        self.addr = addr
        self.daemon = True

    def run(self):
        target = None
        try:
            # Terima handshake awal dari klien
            self.client.recv(BUFLEN)

            host, port = DEFAULT_HOST.split(":")
            target = socket.create_connection((host, int(port)), timeout=10)

            # Kirim balasan sukses switching protocol
            self.client.sendall(RESPONSE.encode())

            while True:
                recv, _, _ = select.select(
                    [self.client, target],
                    [],
                    [],
                    TIMEOUT
                )

                if not recv:
                    break

                for sock in recv:
                    data = sock.recv(BUFLEN)
                    if not data:
                        return

                    if sock == self.client:
                        target.sendall(data)
                    else:
                        self.client.sendall(data)

        except Exception:
            pass

        finally:
            try:
                self.client.close()
            except Exception:
                pass
            
            if target:
                try:
                    target.close()
                except Exception:
                    pass


if __name__ == '__main__':
    print(f"[*] Starting WebSocket Proxy on {LISTENING_ADDR}:{LISTENING_PORT} -> {DEFAULT_HOST}")
    server = Server(LISTENING_ADDR, LISTENING_PORT)
    server.start()

    try:
        while True:
            time.sleep(60)
    except KeyboardInterrupt:
        print("\n[*] Stopping WebSocket Proxy...")
        sys.exit(0)

