# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ngrok is a reverse proxy that creates secure tunnels from public endpoints to locally running services. The project consists of two main components:

- **ngrok client** (`ngrok`): Connects to the server and tunnels traffic to local services. Includes web UI for inspecting HTTP requests/responses.
- **ngrok server** (`ngrokd`): Accepts client connections and routes public traffic through tunnels.

## Build Commands

This project uses a custom GOPATH structure. The Makefile sets `GOPATH` to the repository root.

### Development builds (debug mode)
```bash
make              # Build both client and server
make client       # Build client only (bin/ngrok)
make server       # Build server only (bin/ngrokd)
make fmt          # Format all Go code
```

### Release builds
```bash
make release-client    # Build client with embedded assets
make release-server    # Build server with embedded assets
make release-all       # Format code and build both release binaries
```

### Asset compilation
```bash
make assets           # Compile both client and server assets
make client-assets    # Compile client assets (HTML/CSS/JS, TLS certs)
make server-assets    # Compile server assets (TLS certs)
```

### Other commands
```bash
make deps            # Download Go dependencies
make clean           # Remove built binaries and generated asset files
```

**Important**: Always develop using debug builds (`make` or `make client`/`make server`). Debug builds read static assets from the filesystem, so you don't need to recompile when modifying HTML/CSS/JS files. Release builds embed assets into the binary.

## Running Locally

### Server
```bash
./bin/ngrokd -domain ngrok.me
```

Common server flags:
- `-httpAddr`: Public HTTP address (default `:80`)
- `-httpsAddr`: Public HTTPS address (default `:443`)
- `-tunnelAddr`: Address for ngrok clients (default `:4443`)
- `-domain`: Domain for hosted tunnels (default `ngrok.com`)
- `-tlsCrt`, `-tlsKey`: Paths to TLS certificate and key
- `-log`: Log file path (`stdout` or `none`)
- `-log-level`: Log level (`DEBUG`, `INFO`, `WARNING`, `ERROR`)

### Client
```bash
./bin/ngrok 8080                                    # Tunnel local port 8080
./bin/ngrok -subdomain=test 8080                    # Use specific subdomain
./bin/ngrok -config=debug.yml start test            # Start named tunnel from config
./bin/ngrok -config=debug.yml start-all             # Start all configured tunnels
```

Common client flags:
- `-config`: Path to config file (default `$HOME/.ngrok`)
- `-subdomain`: Request specific subdomain
- `-hostname`: Request specific hostname
- `-proto`: Protocol (`http`, `https`, `tcp`)
- `-httpauth`: HTTP basic auth (`user:password`)
- `-authtoken`: Authentication token
- `-log`: Log file path
- `-log-level`: Log level

### Local development setup

Add to `/etc/hosts`:
```
127.0.0.1 ngrok.me
127.0.0.1 test.ngrok.me
```

Create `debug.yml`:
```yaml
server_addr: ngrok.me:4443
tunnels:
  test:
    proto:
      http: 8080
```

Run server: `./bin/ngrokd -domain ngrok.me`

Run client: `./bin/ngrok -config=debug.yml -log=ngrok.log start test`

## Architecture

### Directory structure
- `src/ngrok/main/ngrok/` - Client binary entry point
- `src/ngrok/main/ngrokd/` - Server binary entry point
- `src/ngrok/client/` - Client implementation
- `src/ngrok/server/` - Server implementation
- `src/ngrok/msg/` - Protocol message definitions
- `src/ngrok/proto/` - Protocol implementations (HTTP, TCP)
- `src/ngrok/conn/` - Connection abstractions
- `src/ngrok/log/` - Logging utilities
- `src/ngrok/util/` - Shared utilities
- `assets/client/` - Client static assets (HTML, CSS, JS, TLS certs)
- `assets/server/` - Server static assets (TLS certs)

### Client architecture

The client uses an MVC pattern:

- **Model** (`src/ngrok/client/model.go`): Manages tunnel state and network connections
- **View** (`src/ngrok/client/views/`): Terminal UI and web UI for displaying requests/responses
- **Controller** (`src/ngrok/client/controller.go`): Coordinates model and views, handles commands

Key components:
- `client/main.go`: Entry point, parses args, loads config, starts controller
- `client/config.go`: Configuration file parsing (YAML format)
- `client/mvc/`: MVC interfaces and state management
- `client/views/term/`: Terminal-based UI
- `client/views/web/`: Web-based inspection interface

### Server architecture

The server manages two types of connections:

1. **Control connections**: Long-lived connections from clients for sending JSON messages
2. **Proxy connections**: Short-lived connections that tunnel actual traffic

Key components:
- `server/main.go`: Entry point, initializes registries, starts listeners
- `server/control.go`: Manages control connections and client authentication
- `server/tunnel.go`: Manages tunnel registration and routing
- `server/registry.go`: Maps public URLs/ports to tunnels
- `server/http.go`: HTTP/HTTPS protocol handler

Global registries:
- `tunnelRegistry`: Maps public URLs to tunnel objects
- `controlRegistry`: Maps client IDs to control connections

### Protocol flow

1. **Connection setup**: Client opens TCP connection to server (control connection)
2. **Authentication**: Client sends `Auth` message, server responds with `AuthResp`
3. **Tunnel creation**: Client sends `ReqTunnel` messages, server responds with `NewTunnel`
4. **Traffic tunneling**:
   - Server receives public connection
   - Server sends `ReqProxy` to client over control connection
   - Client opens new connection (proxy connection) and sends `RegProxy`
   - Server sends `StartProxy` with metadata
   - Server copies traffic between public and proxy connections
   - Client copies traffic between proxy and local connections
5. **Heartbeat**: Client sends `Ping`, server responds with `Pong`

All messages are defined in `src/ngrok/msg/msg.go` with detailed field documentation.

### Message wire format

Messages are sent as netstrings: `<64-bit little-endian length><payload>`

### Protocol implementations

The `proto` package defines a `Protocol` interface for different tunnel types:
- `proto/http.go`: HTTP/HTTPS tunneling with request inspection
- `proto/tcp.go`: Raw TCP tunneling

## Configuration

Client config file (`$HOME/.ngrok` or specified with `-config`):

```yaml
server_addr: ngrok.com:4443
inspect_addr: 127.0.0.1:4040
auth_token: your_token_here
tunnels:
  webapp:
    subdomain: myapp
    proto:
      http: 8080
  ssh:
    proto:
      tcp: 22
    remote_port: 12345
```

## Testing

There are no automated tests in this codebase. Testing is done manually using the local development setup.

## Build requirements

- Go 1.1+
- Mercurial SCM
- `go-bindata` tool (automatically installed by `make bin/go-bindata`)

## Notes

- The project uses a custom GOPATH structure where the repository root is the GOPATH
- Import paths use `ngrok/` prefix (e.g., `import "ngrok/log"`)
- Static assets are embedded in release builds but read from filesystem in debug builds
- The client web interface runs on `localhost:4040` by default (configurable via `inspect_addr`)
