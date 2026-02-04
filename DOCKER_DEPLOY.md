# ngrok Docker 部署指南

本指南介绍如何使用 Docker 部署 ngrok 服务器端和客户端。

## 目录

- [快速开始](#快速开始)
- [部署脚本使用](#部署脚本使用)
- [手动部署](#手动部署)
- [配置说明](#配置说明)
- [常见问题](#常见问题)

## 快速开始

### 1. 准备环境

确保已安装 Docker 和 docker-compose:

```bash
# 检查 Docker 版本
docker --version

# 检查 docker-compose 版本
docker-compose --version
```

### 2. 配置环境变量

复制配置文件模板并修改:

```bash
cp .env.example .env
```

编辑 `.env` 文件，设置你的域名和端口:

```bash
NGROK_DOMAIN=tunnel.yourdomain.com
HTTP_PORT=80
HTTPS_PORT=443
TUNNEL_PORT=4443
LOCAL_PORT=8080
```

### 3. 部署服务器端

```bash
# 使用部署脚本
./deploy.sh deploy-server

# 或使用环境变量
NGROK_DOMAIN=tunnel.yourdomain.com ./deploy.sh deploy-server
```

### 4. 部署客户端

```bash
# 使用部署脚本
./deploy.sh deploy-client

# 或指定本地端口
LOCAL_PORT=3000 ./deploy.sh deploy-client
```

### 5. 使用 docker-compose 部署所有服务

```bash
./deploy.sh deploy-all
```

## 部署脚本使用

`deploy.sh` 脚本提供了完整的部署管理功能。

### 构建镜像

```bash
# 构建服务器端镜像
./deploy.sh build-server

# 构建客户端镜像
./deploy.sh build-client

# 构建所有镜像
./deploy.sh build-all
```

### 部署服务

```bash
# 部署服务器端
./deploy.sh deploy-server

# 部署客户端
./deploy.sh deploy-client

# 部署所有服务 (使用 docker-compose)
./deploy.sh deploy-all
```

### 管理容器

```bash
# 启动容器
./deploy.sh start-server
./deploy.sh start-client
./deploy.sh start-all

# 停止容器
./deploy.sh stop-server
./deploy.sh stop-client
./deploy.sh stop-all

# 重启容器
./deploy.sh restart-server
./deploy.sh restart-client
./deploy.sh restart-all
```

### 查看日志

```bash
# 查看服务器端日志
./deploy.sh logs-server

# 查看客户端日志
./deploy.sh logs-client
```

### 查看状态

```bash
# 查看容器和镜像状态
./deploy.sh status
```

### 清理

```bash
# 清理所有容器和镜像
./deploy.sh clean
```

## 手动部署

### 服务器端手动部署

#### 1. 构建镜像

```bash
docker build -f Dockerfile.server -t ngrokd:latest .
```

#### 2. 运行容器

```bash
docker run -d \
  --name ngrokd \
  --restart unless-stopped \
  -p 80:80 \
  -p 443:443 \
  -p 4443:4443 \
  ngrokd:latest \
  -domain tunnel.yourdomain.com \
  -httpAddr :80 \
  -httpsAddr :443 \
  -tunnelAddr :4443 \
  -log stdout \
  -log-level INFO
```

### 客户端手动部署

#### 1. 构建镜像

```bash
docker build -f Dockerfile.client -t ngrok:latest .
```

#### 2. 运行容器

```bash
docker run -d \
  --name ngrok-client \
  --restart unless-stopped \
  ngrok:latest \
  -server-addr tunnel.yourdomain.com:4443 \
  -log stdout \
  8080
```

### 使用 docker-compose

#### 1. 启动所有服务

```bash
docker-compose up -d
```

#### 2. 查看日志

```bash
docker-compose logs -f
```

#### 3. 停止服务

```bash
docker-compose down
```

## 配置说明

### 环境变量

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `NGROK_DOMAIN` | ngrok 服务器域名 | `ngrok.example.com` |
| `HTTP_PORT` | HTTP 端口 | `80` |
| `HTTPS_PORT` | HTTPS 端口 | `443` |
| `TUNNEL_PORT` | 隧道端口 | `4443` |
| `LOCAL_PORT` | 本地服务端口 | `8080` |
| `IMAGE_TAG` | Docker 镜像标签 | `latest` |

### 服务器端命令行参数

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `-domain` | 隧道托管域名 | `ngrok.com` |
| `-httpAddr` | HTTP 监听地址 | `:80` |
| `-httpsAddr` | HTTPS 监听地址 | `:443` |
| `-tunnelAddr` | 隧道监听地址 | `:4443` |
| `-log` | 日志文件路径 | `stdout` |
| `-log-level` | 日志级别 | `DEBUG` |
| `-tlsCrt` | TLS 证书路径 | - |
| `-tlsKey` | TLS 密钥路径 | - |

### 客户端命令行参数

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `-server-addr` | 服务器地址 | - |
| `-subdomain` | 自定义子域名 | - |
| `-hostname` | 自定义主机名 | - |
| `-proto` | 协议类型 | `http+https` |
| `-log` | 日志文件路径 | `none` |
| `-log-level` | 日志级别 | `DEBUG` |
| `-config` | 配置文件路径 | `$HOME/.ngrok` |

## 使用示例

### 示例 1: 部署公网服务器

```bash
# 设置域名
export NGROK_DOMAIN=tunnel.example.com

# 部署服务器
./deploy.sh deploy-server

# 查看日志
./deploy.sh logs-server
```

### 示例 2: 连接到远程服务器

```bash
# 设置服务器地址
export NGROK_DOMAIN=tunnel.example.com

# 设置本地端口
export LOCAL_PORT=3000

# 部署客户端
./deploy.sh deploy-client
```

### 示例 3: 使用自定义子域名

```bash
docker run -d \
  --name ngrok-client \
  ngrok:latest \
  -server-addr tunnel.example.com:4443 \
  -subdomain myapp \
  -log stdout \
  8080
```

### 示例 4: 使用配置文件

创建配置文件 `ngrok.yml`:

```yaml
server_addr: tunnel.example.com:4443
tunnels:
  webapp:
    subdomain: myapp
    proto:
      http: 8080
  api:
    subdomain: api
    proto:
      http: 3000
```

运行客户端:

```bash
docker run -d \
  --name ngrok-client \
  -v $(pwd)/ngrok.yml:/app/ngrok.yml \
  ngrok:latest \
  -config /app/ngrok.yml \
  start-all
```

## 常见问题

### 1. 端口冲突

如果默认端口被占用，可以修改端口映射:

```bash
HTTP_PORT=8080 HTTPS_PORT=8443 ./deploy.sh deploy-server
```

### 2. 域名解析

确保你的域名 DNS 记录指向服务器 IP:

```
A    tunnel.example.com    -> 服务器IP
A    *.tunnel.example.com  -> 服务器IP (泛域名)
```

### 3. 防火墙配置

确保以下端口在防火墙中开放:
- 80 (HTTP)
- 443 (HTTPS)
- 4443 (隧道)

### 4. TLS 证书

如果需要使用自定义 TLS 证书:

```bash
docker run -d \
  --name ngrokd \
  -p 80:80 -p 443:443 -p 4443:4443 \
  -v /path/to/certs:/app/certs:ro \
  ngrokd:latest \
  -domain tunnel.example.com \
  -tlsCrt /app/certs/server.crt \
  -tlsKey /app/certs/server.key
```

### 5. 查看容器日志

```bash
# 实时查看日志
docker logs -f ngrokd

# 查看最近 100 行日志
docker logs --tail 100 ngrokd
```

### 6. 进入容器调试

```bash
# 进入服务器容器
docker exec -it ngrokd sh

# 进入客户端容器
docker exec -it ngrok-client sh
```

### 7. 更新镜像

```bash
# 重新构建并部署
./deploy.sh deploy-server

# 或使用 docker-compose
docker-compose up -d --build
```

## 性能优化

### 1. 资源限制

在 docker-compose.yml 中添加资源限制:

```yaml
services:
  ngrokd:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 256M
```

### 2. 日志轮转

配置 Docker 日志驱动:

```yaml
services:
  ngrokd:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

## 安全建议

1. **使用 HTTPS**: 配置有效的 TLS 证书
2. **限制访问**: 使用防火墙规则限制访问
3. **定期更新**: 保持 Docker 镜像和依赖更新
4. **监控日志**: 定期检查日志文件
5. **备份配置**: 定期备份配置文件和证书

## 故障排查

### 检查容器状态

```bash
./deploy.sh status
```

### 查看详细日志

```bash
docker logs ngrokd --tail 200
```

### 测试连接

```bash
# 测试服务器端口
telnet tunnel.example.com 4443

# 测试 HTTP 端口
curl http://tunnel.example.com
```

## 更多信息

- [ngrok 官方文档](https://ngrok.com/docs)
- [Docker 官方文档](https://docs.docker.com/)
- [docker-compose 文档](https://docs.docker.com/compose/)
