.PHONY: default server client deps fmt clean all release-all assets client-assets server-assets contributors

BUILDTAGS=debug
default: all

deps:
	go mod download

server: deps assets
	go build -tags '$(BUILDTAGS)' -o bin/ngrokd ./src/ngrok/main/ngrokd

fmt:
	go fmt ./...

client: deps assets
	go build -tags '$(BUILDTAGS)' -o bin/ngrok ./src/ngrok/main/ngrok

assets: client-assets server-assets

client-assets:
	go install github.com/go-bindata/go-bindata/v3/go-bindata@latest
	$$(go env GOPATH)/bin/go-bindata -nomemcopy -pkg=assets -tags=$(BUILDTAGS) \
		-debug=$(if $(findstring debug,$(BUILDTAGS)),true,false) \
		-o=src/ngrok/client/assets/assets_$(BUILDTAGS).go \
		assets/client/...

server-assets:
	go install github.com/go-bindata/go-bindata/v3/go-bindata@latest
	$$(go env GOPATH)/bin/go-bindata -nomemcopy -pkg=assets -tags=$(BUILDTAGS) \
		-debug=$(if $(findstring debug,$(BUILDTAGS)),true,false) \
		-o=src/ngrok/server/assets/assets_$(BUILDTAGS).go \
		assets/server/...

release-client: BUILDTAGS=release
release-client: client

release-server: BUILDTAGS=release
release-server: server

release-all: fmt release-client release-server

all: fmt client server

clean:
	rm -rf bin/ngrok bin/ngrokd
	rm -rf src/ngrok/client/assets/ src/ngrok/server/assets/

contributors:
	echo "Contributors to ngrok, both large and small:\n" > CONTRIBUTORS
	git log --raw | grep "^Author: " | sort | uniq | cut -d ' ' -f2- | sed 's/^/- /' | cut -d '<' -f1 >> CONTRIBUTORS
