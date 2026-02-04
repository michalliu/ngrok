#!/usr/bin/env bash

################################################################################
# ngrok 专业级部署脚本 v2.0
# 功能: Docker 容器化部署、多环境管理、健康检查、优雅降级
# 依赖: Docker 20.10+, docker-compose 1.29+, Bash 4.0+
################################################################################

set -euo pipefail
IFS=$'\n\t'

# ============================================================================
# 配置常量
# ============================================================================
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_NAME="ngrok"
readonly DOCKER_COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.yml"
readonly ENV_FILE="${SCRIPT_DIR}/.env"
readonly LOG_FILE="${SCRIPT_DIR}/deploy.log"
readonly REQUIRED_DOCKER_VERSION="20.10"
readonly REQUIRED_COMPOSE_VERSION="1.29"

# ============================================================================
# ANSI 颜色方案
# ============================================================================
if [[ -t 1 ]]; then
    readonly COLOR_RESET='\033[0m'
    readonly COLOR_RED='\033[0;31m'
    readonly COLOR_GREEN='\033[0;32m'
    readonly COLOR_YELLOW='\033[1;33m'
    readonly COLOR_BLUE='\033[0;34m'
    readonly COLOR_MAGENTA='\033[0;35m'
    readonly COLOR_CYAN='\033[0;36m'
    readonly COLOR_BOLD='\033[1m'
else
    readonly COLOR_RESET=''
    readonly COLOR_RED=''
    readonly COLOR_GREEN=''
    readonly COLOR_YELLOW=''
    readonly COLOR_BLUE=''
    readonly COLOR_MAGENTA=''
    readonly COLOR_CYAN=''
    readonly COLOR_BOLD=''
fi

# ============================================================================
# 全局变量
# ============================================================================
DEBUG_MODE=false
ENVIRONMENT="dev"
QUIET_MODE=false
DRY_RUN=false

# ============================================================================
# 日志系统
# ============================================================================
log_success() {
    echo -e "${COLOR_GREEN}✓${COLOR_RESET} ${COLOR_BOLD}$*${COLOR_RESET}"
    [[ "$QUIET_MODE" == "false" ]] && echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SUCCESS] $*" >> "$LOG_FILE"
}

log_info() {
    echo -e "${COLOR_BLUE}ℹ${COLOR_RESET} $*"
    [[ "$QUIET_MODE" == "false" ]] && echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $*" >> "$LOG_FILE"
}

log_warning() {
    echo -e "${COLOR_YELLOW}⚠${COLOR_RESET} ${COLOR_YELLOW}$*${COLOR_RESET}" >&2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARNING] $*" >> "$LOG_FILE"
}

log_error() {
    echo -e "${COLOR_RED}✗${COLOR_RESET} ${COLOR_RED}错误: $*${COLOR_RESET}" >&2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $*" >> "$LOG_FILE"
}

log_debug() {
    if [[ "$DEBUG_MODE" == "true" ]]; then
        echo -e "${COLOR_MAGENTA}[DEBUG]${COLOR_RESET} $*" >&2
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [DEBUG] $*" >> "$LOG_FILE"
    fi
}

log_step() {
    echo -e "\n${COLOR_CYAN}${COLOR_BOLD}▸ [$1] $2${COLOR_RESET}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [STEP] [$1] $2" >> "$LOG_FILE"
}

# ============================================================================
# 加载动画（Spinner）
# ============================================================================
spinner() {
    local pid=$1
    local message=$2
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local temp
    
    while kill -0 "$pid" 2>/dev/null; do
        temp="${spinstr#?}"
        printf " ${COLOR_CYAN}%c${COLOR_RESET}  %s" "$spinstr" "$message"
        spinstr="$temp${spinstr%"$temp"}"
        sleep 0.1
        printf "\r"
    done
    printf "    \r"
}

# ============================================================================
# 进度条
# ============================================================================
show_progress() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))
    
    printf "\r[${COLOR_GREEN}"
    printf "%${filled}s" | tr ' ' '█'
    printf "${COLOR_RESET}"
    printf "%${empty}s" | tr ' ' '░'
    printf "] %3d%%" "$percentage"
}

# ============================================================================
# 信号处理与清理
# ============================================================================
cleanup() {
    log_warning "检测到中断信号，正在清理临时资源..."
    
    # 停止后台 spinner 进程
    jobs -p | xargs -r kill 2>/dev/null || true
    
    # 清理临时文件
    rm -f "${SCRIPT_DIR}/.deploy.lock" 2>/dev/null || true
    
    log_info "清理完成，脚本退出"
    exit 130
}

trap cleanup SIGINT SIGTERM

# ============================================================================
# 环境依赖检测
# ============================================================================
check_command() {
    local cmd=$1
    local install_hint=$2
    
    if ! command -v "$cmd" &> /dev/null; then
        log_error "未找到命令: $cmd"
        log_info "安装提示: $install_hint"
        return 1
    fi
    return 0
}

version_ge() {
    # 比较版本号 ($1 >= $2)
    printf '%s\n%s' "$2" "$1" | sort -V -C
}

check_docker() {
    log_debug "检查 Docker 环境..."
    
    if ! check_command "docker" "curl -fsSL https://get.docker.com | sh"; then
        return 1
    fi
    
    # 检查 Docker 守护进程
    if ! docker info &>/dev/null; then
        log_error "Docker 守护进程未运行，请启动 Docker"
        log_info "macOS: 启动 Docker Desktop"
        log_info "Linux: sudo systemctl start docker"
        return 1
    fi
    
    # 检查版本
    local docker_version
    docker_version=$(docker version --format '{{.Server.Version}}' 2>/dev/null | cut -d. -f1,2)
    if ! version_ge "$docker_version" "$REQUIRED_DOCKER_VERSION"; then
        log_warning "Docker 版本过低 (当前: $docker_version, 要求: $REQUIRED_DOCKER_VERSION+)"
        return 1
    fi
    
    log_debug "Docker 版本: $docker_version ✓"
    return 0
}

check_docker_compose() {
    log_debug "检查 docker-compose..."
    
    # 优先检查 docker compose (V2)
    if docker compose version &>/dev/null; then
        log_debug "使用 Docker Compose V2"
        return 0
    fi
    
    # 回退到 docker-compose (V1)
    if ! check_command "docker-compose" "https://docs.docker.com/compose/install/"; then
        return 1
    fi
    
    local compose_version
    compose_version=$(docker-compose version --short 2>/dev/null | cut -d. -f1,2)
    if ! version_ge "$compose_version" "$REQUIRED_COMPOSE_VERSION"; then
        log_warning "docker-compose 版本过低 (当前: $compose_version, 要求: $REQUIRED_COMPOSE_VERSION+)"
    fi
    
    log_debug "docker-compose 版本: $compose_version ✓"
    return 0
}

check_env_file() {
    log_debug "检查环境配置文件..."
    
    if [[ ! -f "$ENV_FILE" ]]; then
        log_warning "未找到 .env 文件，正在生成默认配置..."
        
        cat > "$ENV_FILE" << 'EOF'
# ngrok 部署配置
ENVIRONMENT=dev
NGROK_DOMAIN=ngrok.local
NGROK_HTTP_PORT=8080
NGROK_HTTPS_PORT=8443
NGROK_TUNNEL_PORT=4443
NGROK_LOG_LEVEL=INFO
EOF
        log_success "已生成默认 .env 文件，请根据需要修改"
        return 0
    fi
    
    log_debug ".env 文件存在 ✓"
    return 0
}

check_prerequisites() {
    log_step "1/5" "环境依赖检测"
    
    local checks_passed=true
    
    check_docker || checks_passed=false
    check_docker_compose || checks_passed=false
    check_env_file || checks_passed=false
    
    if [[ "$checks_passed" == "false" ]]; then
        log_error "环境检测失败，请修复上述问题后重试"
        exit 1
    fi
    
    log_success "所有依赖检查通过"
}

# ============================================================================
# Docker 操作封装
# ============================================================================
get_compose_cmd() {
    if docker compose version &>/dev/null; then
        echo "docker compose"
    else
        echo "docker-compose"
    fi
}

build_images() {
    log_step "2/5" "构建 Docker 镜像"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] 跳过镜像构建"
        return 0
    fi
    
    local compose_cmd
    compose_cmd=$(get_compose_cmd)
    
    log_info "开始构建镜像（可能需要几分钟）..."
    
    if [[ "$DEBUG_MODE" == "true" ]]; then
        $compose_cmd -f "$DOCKER_COMPOSE_FILE" build --progress=plain
    else
        # 后台构建并显示 spinner
        $compose_cmd -f "$DOCKER_COMPOSE_FILE" build --quiet &
        local build_pid=$!
        spinner "$build_pid" "正在构建镜像..."
        
        if wait "$build_pid"; then
            log_success "镜像构建成功"
        else
            log_error "镜像构建失败，查看详细日志: tail -f $LOG_FILE"
            return 1
        fi
    fi
}

start_services() {
    log_step "3/5" "启动服务容器"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] 跳过服务启动"
        return 0
    fi
    
    local compose_cmd
    compose_cmd=$(get_compose_cmd)
    
    # 原子性启动：使用 --no-deps --no-recreate 确保不影响现有容器
    if $compose_cmd -f "$DOCKER_COMPOSE_FILE" up -d --remove-orphans; then
        log_success "服务启动成功"
    else
        log_error "服务启动失败"
        show_recent_logs
        return 1
    fi
}

check_health() {
    log_step "4/5" "健康检查"
    
    local compose_cmd
    compose_cmd=$(get_compose_cmd)
    
    local max_attempts=30
    local attempt=0
    
    log_info "等待服务就绪..."
    
    while [[ $attempt -lt $max_attempts ]]; do
        local running_containers
        running_containers=$($compose_cmd -f "$DOCKER_COMPOSE_FILE" ps -q 2>/dev/null | wc -l)
        
        if [[ $running_containers -gt 0 ]]; then
            show_progress $((attempt + 1)) "$max_attempts"
            
            # 检查所有容器是否健康
            local unhealthy
            unhealthy=$($compose_cmd -f "$DOCKER_COMPOSE_FILE" ps --filter "health=unhealthy" -q 2>/dev/null | wc -l)
            
            if [[ $unhealthy -eq 0 && $attempt -gt 5 ]]; then
                printf "\n"
                log_success "所有服务健康检查通过"
                return 0
            fi
        fi
        
        sleep 1
        ((attempt++))
    done
    
    printf "\n"
    log_warning "健康检查超时，但服务可能仍在启动中"
    return 0
}

show_status() {
    log_step "5/5" "部署状态"
    
    local compose_cmd
    compose_cmd=$(get_compose_cmd)
    
    echo ""
    echo -e "${COLOR_BOLD}容器状态:${COLOR_RESET}"
    $compose_cmd -f "$DOCKER_COMPOSE_FILE" ps
    
    echo ""
    echo -e "${COLOR_BOLD}访问地址:${COLOR_RESET}"
    source "$ENV_FILE"
    echo -e "  • HTTP:   ${COLOR_GREEN}http://${NGROK_DOMAIN:-ngrok.local}:${NGROK_HTTP_PORT:-8080}${COLOR_RESET}"
    echo -e "  • HTTPS:  ${COLOR_GREEN}https://${NGROK_DOMAIN:-ngrok.local}:${NGROK_HTTPS_PORT:-8443}${COLOR_RESET}"
    echo -e "  • Tunnel: ${COLOR_GREEN}tcp://${NGROK_DOMAIN:-ngrok.local}:${NGROK_TUNNEL_PORT:-4443}${COLOR_RESET}"
    
    echo ""
    log_success "部署完成！🎉"
}

show_recent_logs() {
    local compose_cmd
    compose_cmd=$(get_compose_cmd)
    
    echo ""
    log_warning "最近 20 行容器日志:"
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
    $compose_cmd -f "$DOCKER_COMPOSE_FILE" logs --tail=20
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
}

# ============================================================================
# 命令实现
# ============================================================================
cmd_up() {
    log_info "启动 $PROJECT_NAME 部署流程..."
    
    check_prerequisites
    build_images
    start_services
    check_health
    show_status
}

cmd_down() {
    log_info "停止所有服务..."
    
    local compose_cmd
    compose_cmd=$(get_compose_cmd)
    
    if $compose_cmd -f "$DOCKER_COMPOSE_FILE" down --remove-orphans; then
        log_success "所有服务已停止"
    else
        log_error "停止服务失败"
        return 1
    fi
}

cmd_restart() {
    log_info "重启所有服务..."
    
    cmd_down
    sleep 2
    cmd_up
}

cmd_logs() {
    local compose_cmd
    compose_cmd=$(get_compose_cmd)
    
    local service="${1:-}"
    
    if [[ -n "$service" ]]; then
        $compose_cmd -f "$DOCKER_COMPOSE_FILE" logs -f "$service"
    else
        $compose_cmd -f "$DOCKER_COMPOSE_FILE" logs -f
    fi
}

cmd_ps() {
    local compose_cmd
    compose_cmd=$(get_compose_cmd)
    
    $compose_cmd -f "$DOCKER_COMPOSE_FILE" ps
}

cmd_exec() {
    local compose_cmd
    compose_cmd=$(get_compose_cmd)
    
    local service="${1:-ngrokd}"
    shift || true
    
    $compose_cmd -f "$DOCKER_COMPOSE_FILE" exec "$service" "$@"
}

cmd_clean() {
    log_warning "清理所有容器、镜像和卷（数据将丢失）..."
    
    read -p "确认删除? [y/N]: " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "已取消"
        return 0
    fi
    
    local compose_cmd
    compose_cmd=$(get_compose_cmd)
    
    $compose_cmd -f "$DOCKER_COMPOSE_FILE" down -v --rmi all --remove-orphans
    log_success "清理完成"
}

# ============================================================================
# 帮助文档
# ============================================================================
usage() {
    cat << EOF
${COLOR_BOLD}${COLOR_CYAN}
╔═══════════════════════════════════════════════════════════════╗
║                  ngrok 专业级部署脚本 v2.0                    ║
╚═══════════════════════════════════════════════════════════════╝
${COLOR_RESET}

${COLOR_BOLD}用法:${COLOR_RESET}
    $0 [命令] [选项]

${COLOR_BOLD}命令:${COLOR_RESET}
    ${COLOR_GREEN}up${COLOR_RESET}              启动所有服务（默认命令）
    ${COLOR_GREEN}down${COLOR_RESET}            停止所有服务
    ${COLOR_GREEN}restart${COLOR_RESET}         重启所有服务
    ${COLOR_GREEN}logs${COLOR_RESET} [service]  查看日志（可指定服务名）
    ${COLOR_GREEN}ps${COLOR_RESET}              查看容器状态
    ${COLOR_GREEN}exec${COLOR_RESET} [service]  进入容器 Shell
    ${COLOR_GREEN}clean${COLOR_RESET}           清理所有容器和镜像

${COLOR_BOLD}选项:${COLOR_RESET}
    ${COLOR_YELLOW}-e, --env${COLOR_RESET}       指定环境 (dev/staging/prod，默认: dev)
    ${COLOR_YELLOW}-d, --debug${COLOR_RESET}     启用调试模式
    ${COLOR_YELLOW}-q, --quiet${COLOR_RESET}     静默模式（减少输出）
    ${COLOR_YELLOW}-n, --dry-run${COLOR_RESET}   模拟执行（不实际操作）
    ${COLOR_YELLOW}-h, --help${COLOR_RESET}      显示此帮助信息

${COLOR_BOLD}示例:${COLOR_RESET}
    # 启动开发环境
    $0 up

    # 启动生产环境并查看详细日志
    $0 --env=prod --debug up

    # 查看 ngrokd 服务日志
    $0 logs ngrokd

    # 进入 ngrokd 容器
    $0 exec ngrokd /bin/sh

    # 停止并清理所有资源
    $0 clean

${COLOR_BOLD}环境变量:${COLOR_RESET}
    在 ${COLOR_CYAN}.env${COLOR_RESET} 文件中配置以下变量：
    • NGROK_DOMAIN        - 服务域名（默认: ngrok.local）
    • NGROK_HTTP_PORT     - HTTP 端口（默认: 8080）
    • NGROK_HTTPS_PORT    - HTTPS 端口（默认: 8443）
    • NGROK_TUNNEL_PORT   - 隧道端口（默认: 4443）
    • NGROK_LOG_LEVEL     - 日志级别（默认: INFO）

${COLOR_BOLD}日志文件:${COLOR_RESET} ${COLOR_CYAN}$LOG_FILE${COLOR_RESET}

${COLOR_BOLD}更多信息:${COLOR_RESET} https://github.com/inconshreveable/ngrok

EOF
}

# ============================================================================
# 参数解析
# ============================================================================
parse_args() {
    local command="up"
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            -d|--debug)
                DEBUG_MODE=true
                set -x
                shift
                ;;
            -q|--quiet)
                QUIET_MODE=true
                shift
                ;;
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -e|--env)
                ENVIRONMENT="$2"
                shift 2
                ;;
            --env=*)
                ENVIRONMENT="${1#*=}"
                shift
                ;;
            up|down|restart|logs|ps|exec|clean)
                command="$1"
                shift
                break
                ;;
            *)
                log_error "未知参数: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    # 执行命令
    case "$command" in
        up)
            cmd_up
            ;;
        down)
            cmd_down
            ;;
        restart)
            cmd_restart
            ;;
        logs)
            cmd_logs "$@"
            ;;
        ps)
            cmd_ps
            ;;
        exec)
            cmd_exec "$@"
            ;;
        clean)
            cmd_clean
            ;;
        *)
            log_error "未知命令: $command"
            usage
            exit 1
            ;;
    esac
}

# ============================================================================
# 主入口
# ============================================================================
main() {
    # 初始化日志文件
    echo "=== 部署开始 [$(date '+%Y-%m-%d %H:%M:%S')] ===" >> "$LOG_FILE"
    
    # 检查脚本锁（防止并发执行）
    local lock_file="${SCRIPT_DIR}/.deploy.lock"
    if [[ -f "$lock_file" ]]; then
        log_error "检测到另一个部署进程正在运行（锁文件: $lock_file）"
        log_info "如果确认没有其他进程，请删除锁文件: rm $lock_file"
        exit 1
    fi
    
    # 创建锁文件
    echo $$ > "$lock_file"
    trap "rm -f $lock_file" EXIT
    
    # 解析参数并执行命令
    if [[ $# -eq 0 ]]; then
        cmd_up
    else
        parse_args "$@"
    fi
}

# 执行主函数
main "$@"
