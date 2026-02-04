# ============================================================================
# ngrok Server Dockerfile - 多阶段构建
# ============================================================================

# 阶段 1: 构建环境
FROM golang:1.19-alpine AS builder

# 安装构建依赖
RUN apk add --no-cache \
    git \
    mercurial \
    make \
    gcc \
    musl-dev

# 设置工作目录
WORKDIR /ngrok

# 复制源码
COPY . .

# 构建 ngrokd 服务器
RUN make release-server

# ============================================================================
# 阶段 2: 运行环境
FROM alpine:3.18

# 安装运行时依赖
RUN apk add --no-cache \
    ca-certificates \
    tzdata

# 创建非 root 用户
RUN addgroup -g 1000 ngrok && \
    adduser -D -u 1000 -G ngrok ngrok

# 设置工作目录
WORKDIR /app

# 从构建阶段复制二进制文件
COPY --from=builder /ngrok/bin/ngrokd /app/ngrokd

# 复制资源文件（如果需要）
COPY --from=builder /ngrok/assets /app/assets

# 修改所有权
RUN chown -R ngrok:ngrok /app

# 切换到非 root 用户
USER ngrok

# 暴露端口
# 80/443 - HTTP/HTTPS 公共端口
# 4443 - ngrok 客户端连接端口
EXPOSE 80 443 4443

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD pidof ngrokd || exit 1

# 启动命令
ENTRYPOINT ["/app/ngrokd"]

# 默认参数（可通过 docker-compose 覆盖）
CMD ["-domain=ngrok.local", "-httpAddr=:80", "-httpsAddr=:443", "-tunnelAddr=:4443"]
