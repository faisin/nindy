package main

import (
	"io"
	"log"
	"net"
)

const (
	ListenAddr = "0.0.0.0:2082"
	TargetAddr = "127.0.0.1:109"

	BufLen = 4096 * 4
)

var Response = []byte(
	"HTTP/1.1 101 Znandxyz Server Connected\r\n" +
		"Content-Length: 104857600000\r\n" +
		"\r\n",
)

func main() {
	ln, err := net.Listen("tcp", ListenAddr)
	if err != nil {
		log.Fatalf("listen error: %v", err)
	}

	log.Printf("SSH WS listening on %s -> %s", ListenAddr, TargetAddr)

	for {
		conn, err := ln.Accept()
		if err != nil {
			log.Printf("accept error: %v", err)
			continue
		}

		go handle(conn)
	}
}

func handle(client net.Conn) {
	defer client.Close()

	log.Printf("new connection: %s", client.RemoteAddr())

	buf := make([]byte, BufLen)

	n, err := client.Read(buf)
	if err != nil {
		log.Printf("read error: %v", err)
		return
	}

	target, err := net.Dial("tcp", TargetAddr)
	if err != nil {
		log.Printf("target connect error: %v", err)
		return
	}
	defer target.Close()

	_, err = client.Write(Response)
	if err != nil {
		log.Printf("response write error: %v", err)
		return
	}

	// Menggabungkan sisa buffer yang sudah terbaca dengan koneksi klien menggunakan io.MultiReader
	initialData := io.NopCloser(io.LimitReader(net.Conn(client), int64(n))) // placeholder logik buffer
	// Agar lebih aman dengan data yang sudah dibaca di 'buf[:n]':
	clientStream := io.MultiReader(
		io.LimitReader(net.NewBuffer(buf[:n]), int64(n)),
		client,
	)

	go func() {
		_, err := io.Copy(target, clientStream)
		if err != nil && err != io.EOF {
			log.Printf("client->target error: %v", err)
		}

		if tcp, ok := target.(*net.TCPConn); ok {
			_ = tcp.CloseWrite()
		}
	}()

	_, err = io.Copy(client, target)
	if err != nil && err != io.EOF {
		log.Printf("target->client error: %v", err)
	}

	log.Printf("connection closed: %s", client.RemoteAddr())
}

