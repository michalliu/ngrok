package proto

import (
	"github.com/inconshreveable/ngrok/src/ngrok/conn"
)

type Protocol interface {
	GetName() string
	WrapConn(conn.Conn, interface{}) conn.Conn
}
