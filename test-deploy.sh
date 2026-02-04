#!/usr/bin/env bash

################################################################################
# deploy.sh 功能测试脚本
# 用途: 验证部署脚本的各项功能是否正常工作
################################################################################

set -euo pipefail

readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly RESET='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0

# 测试辅助函数
assert_command_exists() {
    local cmd=$1
    if command -v "$cmd" &> /dev/null; then
        echo -e "${GREEN}✓${RESET} 命令存在: $cmd"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${RESET} 命令不存在: $cmd"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_file_exists() {
    local file=$1
    if [[ -f "$file" ]]; then
        echo -e "${GREEN}✓${RESET} 文件存在: $file"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${RESET} 文件不存在: $file"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_file_executable() {
    local file=$1
    if [[ -x "$file" ]]; then
        echo -e "${GREEN}✓${RESET} 文件可执行: $file"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${RESET} 文件不可执行: $file"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_command_succeeds() {
    local description=$1
    shift
    if "$@" &> /dev/null; then
        echo -e "${GREEN}✓${RESET} $description"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${RESET} $description"
        ((TESTS_FAILED++))
        return 1
    fi
}

# 开始测试
echo "========================================"
echo "  deploy.sh 功能测试套件"
echo "========================================"
echo ""

echo "测试 1: 系统依赖检查"
echo "----------------------------------------"
assert_command_exists "bash"
assert_command_exists "docker"
assert_command_exists "git"
echo ""

echo "测试 2: 文件完整性检查"
echo "----------------------------------------"
assert_file_exists "deploy.sh"
assert_file_exists "Dockerfile"
assert_file_exists "Dockerfile.client"
assert_file_exists "docker-compose.yml"
assert_file_exists ".env.example"
assert_file_exists "config/ngrok-client.yml"
assert_file_exists "DEPLOY.md"
echo ""

echo "测试 3: 脚本权限检查"
echo "----------------------------------------"
if [[ ! -x "deploy.sh" ]]; then
    echo -e "${YELLOW}⚠${RESET} deploy.sh 不可执行，正在设置权限..."
    chmod +x deploy.sh
    assert_file_executable "deploy.sh"
else
    assert_file_executable "deploy.sh"
fi
echo ""

echo "测试 4: 帮助系统测试"
echo "----------------------------------------"
assert_command_succeeds "显示帮助信息" ./deploy.sh --help
echo ""

echo "测试 5: 环境变量检查"
echo "----------------------------------------"
if [[ ! -f ".env" ]]; then
    echo -e "${YELLOW}⚠${RESET} .env 文件不存在，测试自动生成功能..."
    ./deploy.sh --dry-run up || true
    assert_file_exists ".env"
else
    echo -e "${GREEN}✓${RESET} .env 文件已存在"
    ((TESTS_PASSED++))
fi
echo ""

echo "测试 6: Docker 环境检查"
echo "----------------------------------------"
if docker info &> /dev/null; then
    echo -e "${GREEN}✓${RESET} Docker 守护进程运行正常"
    ((TESTS_PASSED++))
    
    # 检查 Docker Compose
    if docker compose version &> /dev/null; then
        echo -e "${GREEN}✓${RESET} Docker Compose V2 可用"
        ((TESTS_PASSED++))
    elif command -v docker-compose &> /dev/null; then
        echo -e "${GREEN}✓${RESET} docker-compose V1 可用"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${RESET} 未找到 docker-compose"
        ((TESTS_FAILED++))
    fi
else
    echo -e "${RED}✗${RESET} Docker 守护进程未运行"
    ((TESTS_FAILED++))
    echo -e "${YELLOW}  提示: 请先启动 Docker${RESET}"
fi
echo ""

echo "测试 7: Dry-run 模式测试"
echo "----------------------------------------"
assert_command_succeeds "模拟部署执行" ./deploy.sh --dry-run up
echo ""

# 测试总结
echo "========================================"
echo "  测试结果汇总"
echo "========================================"
echo -e "通过: ${GREEN}$TESTS_PASSED${RESET}"
echo -e "失败: ${RED}$TESTS_FAILED${RESET}"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}🎉 所有测试通过！部署脚本已准备就绪。${RESET}"
    echo ""
    echo "下一步操作:"
    echo "  1. 配置环境变量: vim .env"
    echo "  2. 启动服务: ./deploy.sh up"
    echo "  3. 查看帮助: ./deploy.sh --help"
    exit 0
else
    echo -e "${RED}❌ 部分测试失败，请检查上述问题。${RESET}"
    exit 1
fi
