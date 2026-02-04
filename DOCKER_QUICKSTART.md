# ngrok Docker 快速参考

## 一键部署

```bash
# 服务器端
NGROK_DOMAIN=tunnel.yourdomain.com ./deploy.sh deploy-server

# 客户端
LOCAL_PORT=8080 ./deploy.sh deploy-client

# 全部 (docker-compose)
./deploy.sh deploy-all
```

## 常用命令

| 命令 | 说明 |
|------|------|
| `./deploy.sh build-server` | 构建服务器镜像 |
| `./deploy.sh build-client` | 构建客户端镜像 |
| `./deploy.sh deploy-server` | 部署服务器 |
| `./deploy.sh deploy-client` | 部署客户端 |
| `./deploy.sh logs-server` | 查看服务器日志 |
| `./deploy.sh logs-client` | 查看客户端日志 |
| `./deploy.sh status` | 查看状态 |
| `./deploy.sh clean` | 清理所有 |

## 环境变量

```bash
export NGROK_DOMAIN=tunnel.example.com
export HTTP_PORT=80
export HTTPS_PORT=443
export TUNNEL_PORT=4443
export LOCAL_PORT=8080
```

## Docker Compose

```bash
# 启动
docker-compose up -d

# 停止
docker-compose down

# 查看日志
docker-compose logs -f

# 重启
docker-compose restart
```

## 手动 Docker 命令

### 服务器

```bash
# 构建
docker build -f Dockerfile.server -t ngrokd:latest .

# 运行
docker run -d --name ngrokd \
  -p 80:80 -p 443:443 -p 4443:4443 \
  ngrokd:latest \
  -domain tunnel.example.com
```

### 客户端

```bash
# 构建
docker build -f Dockerfile.client -t ngrok:latest .

# 运行
docker run -d --name ngrok-client \
  ngrok:latest \
  -server-addr tunnel.example.com:4443 \
  8080
```

## 故障排查

```bash
# 查看容器状态
docker ps -a

# 查看日志
docker logs ngrokd
docker logs ngrok-client

# 进入容器
docker exec -it ngrokd sh

# 重启容器
docker restart ngrokd
```

## DNS 配置

```
A    tunnel.example.com      -> 服务器IP
A    *.tunnel.example.com    -> 服务器IP
```

## 防火墙端口

- 80 (HTTP)
- 443 (HTTPS)
- 4443 (隧道)

## 更多信息

详细文档: [DOCKER_DEPLOY.md](DOCKER_DEPLOY.md)
