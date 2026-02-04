#!/bin/bash

#############################################
# ngrok Docker Deployment Script
# 支持服务器端和客户端的构建与部署
#############################################

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 默认配置
NGROK_DOMAIN="${NGROK_DOMAIN:-ngrok.example.com}"
HTTP_PORT="${HTTP_PORT:-80}"
HTTPS_PORT="${HTTPS_PORT:-443}"
TUNNEL_PORT="${TUNNEL_PORT:-4443}"
LOCAL_PORT="${LOCAL_PORT:-8080}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 显示帮助信息
show_help() {
    cat << EOF
ngrok Docker 部署脚本

用法: $0 [命令] [选项]

命令:
  build-server          构建服务器端 Docker 镜像
  build-client          构建客户端 Docker 镜像
  build-all             构建服务器端和客户端镜像

  deploy-server         部署服务器端
  deploy-client         部署客户端
  deploy-all            部署服务器端和客户端

  start-server          启动服务器端容器
  start-client          启动客户端容器
  start-all             启动所有容器

  stop-server           停止服务器端容器
  stop-client           停止客户端容器
  stop-all              停止所有容器

  restart-server        重启服务器端容器
  restart-client        重启客户端容器
  restart-all           重启所有容器

  logs-server           查看服务器端日志
  logs-client           查看客户端日志

  clean                 清理容器和镜像
  status                查看容器状态

  help                  显示此帮助信息

环境变量:
  NGROK_DOMAIN          ngrok 服务器域名 (默认: ngrok.example.com)
  HTTP_PORT             HTTP 端口 (默认: 80)
  HTTPS_PORT            HTTPS 端口 (默认: 443)
  TUNNEL_PORT           隧道端口 (默认: 4443)
  LOCAL_PORT            本地服务端口 (默认: 8080)
  IMAGE_TAG             镜像标签 (默认: latest)

示例:
  # 构建并部署服务器端
  NGROK_DOMAIN=tunnel.example.com $0 deploy-server

  # 构建并部署客户端
  LOCAL_PORT=3000 $0 deploy-client

  # 使用 docker-compose 部署所有服务
  $0 deploy-all

  # 查看服务器日志
  $0 logs-server

EOF
}

# 检查 Docker 是否安装
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker 未安装，请先安装 Docker"
        exit 1
    fi
    print_success "Docker 已安装"
}

# 检查 docker-compose 是否安装
check_docker_compose() {
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "docker-compose 未安装，请先安装 docker-compose"
        exit 1
    fi
    print_success "docker-compose 已安装"
}

# 构建服务器端镜像
build_server() {
    print_info "开始构建服务器端镜像..."
    docker build -f Dockerfile.server -t ngrokd:${IMAGE_TAG} .
    print_success "服务器端镜像构建完成: ngrokd:${IMAGE_TAG}"
}

# 构建客户端镜像
build_client() {
    print_info "开始构建客户端镜像..."
    docker build -f Dockerfile.client -t ngrok:${IMAGE_TAG} .
    print_success "客户端镜像构建完成: ngrok:${IMAGE_TAG}"
}

# 构建所有镜像
build_all() {
    build_server
    build_client
}

# 部署服务器端
deploy_server() {
    print_info "部署服务器端..."

    # 停止并删除旧容器
    docker stop ngrokd 2>/dev/null || true
    docker rm ngrokd 2>/dev/null || true

    # 构建镜像
    build_server

    # 启动容器
    print_info "启动服务器端容器..."
    docker run -d \
        --name ngrokd \
        --restart unless-stopped \
        -p ${HTTP_PORT}:80 \
        -p ${HTTPS_PORT}:443 \
        -p ${TUNNEL_PORT}:4443 \
        -e DOMAIN=${NGROK_DOMAIN} \
        ngrokd:${IMAGE_TAG} \
        -domain ${NGROK_DOMAIN} \
        -httpAddr :80 \
        -httpsAddr :443 \
        -tunnelAddr :4443 \
        -log stdout \
        -log-level INFO

    print_success "服务器端部署完成"
    print_info "服务器地址: ${NGROK_DOMAIN}"
    print_info "HTTP 端口: ${HTTP_PORT}"
    print_info "HTTPS 端口: ${HTTPS_PORT}"
    print_info "隧道端口: ${TUNNEL_PORT}"
}

# 部署客户端
deploy_client() {
    print_info "部署客户端..."

    # 停止并删除旧容器
    docker stop ngrok-client 2>/dev/null || true
    docker rm ngrok-client 2>/dev/null || true

    # 构建镜像
    build_client

    # 启动容器
    print_info "启动客户端容器..."
    docker run -d \
        --name ngrok-client \
        --restart unless-stopped \
        -e SERVER_ADDR=${NGROK_DOMAIN}:${TUNNEL_PORT} \
        -e LOCAL_PORT=${LOCAL_PORT} \
        ngrok:${IMAGE_TAG} \
        -server-addr ${NGROK_DOMAIN}:${TUNNEL_PORT} \
        -log stdout \
        ${LOCAL_PORT}

    print_success "客户端部署完成"
    print_info "服务器地址: ${NGROK_DOMAIN}:${TUNNEL_PORT}"
    print_info "本地端口: ${LOCAL_PORT}"
}

# 使用 docker-compose 部署所有服务
deploy_all() {
    print_info "使用 docker-compose 部署所有服务..."
    check_docker_compose

    export NGROK_DOMAIN
    export LOCAL_PORT

    docker-compose down 2>/dev/null || true
    docker-compose up -d --build

    print_success "所有服务部署完成"
}

# 启动服务器端
start_server() {
    print_info "启动服务器端容器..."
    docker start ngrokd
    print_success "服务器端已启动"
}

# 启动客户端
start_client() {
    print_info "启动客户端容器..."
    docker start ngrok-client
    print_success "客户端已启动"
}

# 启动所有容器
start_all() {
    print_info "启动所有容器..."
    docker-compose start
    print_success "所有容器已启动"
}

# 停止服务器端
stop_server() {
    print_info "停止服务器端容器..."
    docker stop ngrokd
    print_success "服务器端已停止"
}

# 停止客户端
stop_client() {
    print_info "停止客户端容器..."
    docker stop ngrok-client
    print_success "客户端已停止"
}

# 停止所有容器
stop_all() {
    print_info "停止所有容器..."
    docker-compose stop
    print_success "所有容器已停止"
}

# 重启服务器端
restart_server() {
    print_info "重启服务器端容器..."
    docker restart ngrokd
    print_success "服务器端已重启"
}

# 重启客户端
restart_client() {
    print_info "重启客户端容器..."
    docker restart ngrok-client
    print_success "客户端已重启"
}

# 重启所有容器
restart_all() {
    print_info "重启所有容器..."
    docker-compose restart
    print_success "所有容器已重启"
}

# 查看服务器端日志
logs_server() {
    print_info "查看服务器端日志 (Ctrl+C 退出)..."
    docker logs -f ngrokd
}

# 查看客户端日志
logs_client() {
    print_info "查看客户端日志 (Ctrl+C 退出)..."
    docker logs -f ngrok-client
}

# 清理容器和镜像
clean() {
    print_warning "清理所有 ngrok 容器和镜像..."
    read -p "确认清理? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker-compose down 2>/dev/null || true
        docker stop ngrokd ngrok-client 2>/dev/null || true
        docker rm ngrokd ngrok-client 2>/dev/null || true
        docker rmi ngrokd:${IMAGE_TAG} ngrok:${IMAGE_TAG} 2>/dev/null || true
        print_success "清理完成"
    else
        print_info "取消清理"
    fi
}

# 查看容器状态
status() {
    print_info "容器状态:"
    echo ""
    docker ps -a --filter "name=ngrok" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    print_info "镜像列表:"
    echo ""
    docker images --filter "reference=ngrok*" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
}

# 主函数
main() {
    # 检查 Docker
    check_docker

    # 解析命令
    case "${1:-help}" in
        build-server)
            build_server
            ;;
        build-client)
            build_client
            ;;
        build-all)
            build_all
            ;;
        deploy-server)
            deploy_server
            ;;
        deploy-client)
            deploy_client
            ;;
        deploy-all)
            deploy_all
            ;;
        start-server)
            start_server
            ;;
        start-client)
            start_client
            ;;
        start-all)
            start_all
            ;;
        stop-server)
            stop_server
            ;;
        stop-client)
            stop_client
            ;;
        stop-all)
            stop_all
            ;;
        restart-server)
            restart_server
            ;;
        restart-client)
            restart_client
            ;;
        restart-all)
            restart_all
            ;;
        logs-server)
            logs_server
            ;;
        logs-client)
            logs_client
            ;;
        clean)
            clean
            ;;
        status)
            status
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "未知命令: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"
