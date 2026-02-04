# ngrok - Unified Ingress for Developers

[https://ngrok.com](https://ngrok.com)

## ngrok Community on GitHub

If you are having an issue with the ngrok cloud service please open an issue on the [ngrok community on GitHub](https://github.com/ngrok/ngrok)

## This repository is archived

This is the GitHub repository for the old v1 version of ngrok which was actively developed from 2013-2016.

**This repository is archived: ngrok v1 is no longer developed, supported or maintained.**

Thank you to everyone who contributed to ngrok v1 it in its early days with PRs, issues and feedback. If you wish to continue development on this codebase, please fork it.

ngrok's cloud service continues to operate and you can sign up for it here: [https://ngrok.com/signup](https://ngrok.com/signup)

---

## 🚀 Modernized Fork - Go 1.21+ Support

This fork has been upgraded to support modern Go versions (Go 1.21+) with the following improvements:

- ✅ **Go Modules** support
- ✅ Updated to **Go 1.21+** (tested with Go 1.25.5)
- ✅ Removed deprecated APIs (`io/ioutil`, `rand.Seed`)
- ✅ Updated dependencies (yaml.v3, latest go-metrics, etc.)
- ✅ **Docker deployment** support with automated scripts
- ✅ Modern build system

### Quick Start with Docker

Deploy ngrok server and client using Docker:

```bash
# Deploy server
NGROK_DOMAIN=tunnel.yourdomain.com ./deploy.sh deploy-server

# Deploy client
LOCAL_PORT=8080 ./deploy.sh deploy-client

# Or deploy everything with docker-compose
./deploy.sh deploy-all
```

See [DOCKER_DEPLOY.md](DOCKER_DEPLOY.md) for detailed Docker deployment instructions.

### Build from Source

```bash
# Build debug version
make

# Build release version
make release-all

# Run server
./bin/ngrokd -domain ngrok.me

# Run client
./bin/ngrok 8080
```

See [CLAUDE.md](CLAUDE.md) for detailed build and development instructions.

---

## What is ngrok?

ngrok is a globally distributed reverse proxy that secures, protects and accelerates your applications and network services, no matter where you run them. You can think of ngrok as the front door to your applications. ngrok combines your reverse proxy, firewall, API gateway, and global load balancing into one. ngrok can capture and analyze all traffic to your web service for later inspection and replay.

To use ngrok, sign up at [https://ngrok.com/signup](https://ngrok.com/signup)

## ngrok open-source development
ngrok continues to contribute to the open source ecosystem at [https://github.com/ngrok](https://github.com/ngrok) with:
- [The ngrok kubernetes operator](https://github.com/ngrok/kubernetes-ingress-controller)
- [The ngrok agent SDKs](https://ngrok.com/docs/agent-sdks/) for [Python](https://github.com/ngrok/ngrok-python), [JavaScript](https://github.com/ngrok/ngrok-javascript), [Go](https://github.com/ngrok/ngrok-go), [Rust](https://github.com/ngrok/ngrok-rust) and [Java](https://github.com/ngrok/ngrok-java)


## What is ngrok for?

[What can you do with ngrok?](https://ngrok.com/docs/what-is-ngrok/#what-can-you-do-with-ngrok)

- Site-to-site Connectivity: Connect securely to APIs and databases in your customers' networks without complex network configuration.
- Developer Previews: Demoing an app from your local machine without deploying it
- Webhook Testing: Developing any services which consume webhooks (HTTP callbacks) by allowing you to replay those requests
- API Gateway: An global gateway-as-a-service that works for API running anywhere with simple CEL-based traffic policy for rate limiting, jwt authentication and more.
- Device Gateway: Run ngrok on your IoT devices to control device APIs from your cloud
- Debug and understand any web service by inspecting the HTTP traffic to it
