# 🐳 ngrok Docker 容器化部署

> **专业级部署脚本**，提供优雅的开发者体验 (DX)

---

## ✨ 核心特性

### 🛡️ 环境自愈与校验
- ✅ 自动检测 Docker、docker-compose 依赖
- ✅ 智能版本兼容性检查（Docker 20.10+, Compose 1.29+）
- ✅ 缺失配置文件自动生成（.env）
- ✅ 清晰的错误提示与修复引导

### 🎨 视觉反馈系统
- 🎨 **ANSI 颜色方案**：成功（绿）、警告（黄）、错误（红）、信息（蓝）
- 🔄 **加载动画**：Spinner 动画显示长时间操作进度
- 📊 **进度条**：健康检查实时进度可视化
- 📝 **步骤透明**：清晰的 [1/5] 步骤说明

### 🛠️ 鲁棒性保障
- ⚛️ **原子操作**：构建失败不影响运行中容器
- 🔒 **进程锁**：防止并发执行导致状态混乱
- 🚦 **信号处理**：Ctrl+C 优雅退出并清理临时资源
- 🌍 **多环境支持**：dev/staging/prod 配置切换

### 🔍 调试友好
- 🐛 `--debug` 模式输出详细执行日志
- 📋 失败时自动展示最后 20 行容器日志
- 💾 持久化日志文件 `deploy.log`
- 🔎 干运行模式 `--dry-run` 验证配置

---

## 🚀 快速开始

### 一键部署

```bash
# 1. 设置执行权限
chmod +x deploy.sh

# 2. 启动服务（自动检测环境并生成配置）
./deploy.sh up

# 3. 查看运行状态
./deploy.sh ps
```

### 首次配置

```bash
# 复制环境变量模板
cp .env.example .env

# 根据需要修改配置
vim .env
```

---

## 📚 命令参考

### 🎯 基础命令

| 命令 | 功能 | 示例 |
|------|------|------|
| `up` | 启动所有服务（默认） | `./deploy.sh up` |
| `down` | 停止所有服务 | `./deploy.sh down` |
| `restart` | 重启服务 | `./deploy.sh restart` |
| `logs [service]` | 查看日志（可指定服务） | `./deploy.sh logs ngrokd` |
| `ps` | 查看容器状态 | `./deploy.sh ps` |
| `exec [service]` | 进入容器 Shell | `./deploy.sh exec ngrokd sh` |
| `clean` | 清理所有资源 | `./deploy.sh clean` |

### ⚙️ 选项参数

| 参数 | 说明 | 示例 |
|------|------|------|
| `-e, --env` | 指定环境 | `./deploy.sh --env=prod up` |
| `-d, --debug` | 启用调试模式 | `./deploy.sh --debug up` |
| `-q, --quiet` | 静默模式（减少输出） | `./deploy.sh --quiet up` |
| `-n, --dry-run` | 模拟执行（不实际操作） | `./deploy.sh --dry-run up` |
| `-h, --help` | 显示帮助信息 | `./deploy.sh --help` |

---

## 💡 使用场景

### 场景 1️⃣: 本地开发环境

```bash
# 配置本地域名解析
echo "127.0.0.1 ngrok.local" | sudo tee -a /etc/hosts

# 启动开发环境
./deploy.sh up

# 访问服务
curl http://ngrok.local:8080
```

### 场景 2️⃣: 生产环境部署

```bash
# 使用生产配置
./deploy.sh --env=prod up

# 后台运行并实时查看日志
./deploy.sh logs -f
```

### 场景 3️⃣: 调试问题

```bash
# 启用调试模式获取详细日志
./deploy.sh --debug up

# 进入容器排查问题
./deploy.sh exec ngrokd sh

# 查看持久化日志
tail -f deploy.log
```

### 场景 4️⃣: 健康检查

```bash
# 查看容器运行状态
./deploy.sh ps

# 查看最近日志
./deploy.sh logs --tail=50

# 检查服务健康状态
docker inspect --format='{{.State.Health.Status}}' ngrokd
```

---

## 📊 脚本架构亮点

### 模块化设计

```bash
deploy.sh
├── 配置管理       # 常量、颜色方案、全局变量
├── 日志系统       # log_success/info/warning/error/debug
├── UI 组件        # spinner、progress bar
├── 信号处理       # cleanup、trap
├── 环境检测       # check_docker、check_compose、check_env
├── Docker 操作    # build_images、start_services、check_health
├── 命令实现       # cmd_up、cmd_down、cmd_restart...
└── 参数解析       # parse_args、usage
```

### 日志系统示例

```bash
log_success "镜像构建成功"           # ✓ 绿色粗体
log_info "开始健康检查..."          # ℹ 蓝色普通
log_warning "Docker 版本过低"       # ⚠ 黄色警告
log_error "服务启动失败"            # ✗ 红色错误
log_debug "调试信息: 镜像 ID=abc"   # [DEBUG] 紫色（仅 --debug 可见）
```

### 进度反馈示例

```bash
# Spinner 动画
⠋  正在构建镜像...

# 进度条
[████████████████████████░░░░░░░░] 70%
```

---

## 🧪 测试套件

运行自动化测试验证部署脚本功能：

```bash
# 运行测试套件
./test-deploy.sh

# 测试输出示例
========================================
  deploy.sh 功能测试套件
========================================

测试 1: 系统依赖检查
----------------------------------------
✓ 命令存在: bash
✓ 命令存在: docker
✓ 命令存在: git

测试 2: 文件完整性检查
----------------------------------------
✓ 文件存在: deploy.sh
✓ 文件存在: Dockerfile
✓ 文件存在: docker-compose.yml

...

========================================
  测试结果汇总
========================================
通过: 15
失败: 0

🎉 所有测试通过！部署脚本已准备就绪。
```

---

## 📁 项目结构

```
ngrok/
├── deploy.sh              # 🎯 主部署脚本（核心）
├── test-deploy.sh         # 🧪 测试套件
├── Dockerfile             # 🐳 服务端镜像定义
├── Dockerfile.client      # 🐳 客户端镜像定义
├── docker-compose.yml     # 🎼 容器编排配置
├── .env                   # 🔐 环境变量（需创建）
├── .env.example           # 📝 环境变量模板
├── .dockerignore          # 🚫 构建忽略文件
├── Makefile.deploy        # 📦 Make 命令集成
├── config/
│   └── ngrok-client.yml   # ⚙️ 客户端配置示例
├── DEPLOY.md              # 📖 部署详细文档
└── README.Docker.md       # 📘 本文档
```

---

## 🔥 与传统脚本的对比

| 特性 | 传统脚本 | 本脚本 |
|------|----------|--------|
| **环境检测** | ❌ 手动检查 | ✅ 自动检测并引导修复 |
| **视觉反馈** | ❌ 纯文本输出 | ✅ 颜色+动画+进度条 |
| **错误处理** | ❌ 直接退出 | ✅ 展示详细日志并提示 |
| **原子性** | ❌ 构建失败影响现有容器 | ✅ 构建失败不影响运行 |
| **信号处理** | ❌ Ctrl+C 留下僵尸进程 | ✅ 优雅清理临时资源 |
| **调试能力** | ❌ 需手动查看日志 | ✅ --debug + 自动展示日志 |
| **多环境支持** | ❌ 手动修改配置 | ✅ --env 参数切换 |
| **帮助系统** | ❌ 读源码理解 | ✅ --help 标准化文档 |

---

## 🔧 高级用法

### 集成到 Makefile

```bash
# 在主 Makefile 中添加
include Makefile.deploy

# 然后可以使用
make docker-up
make docker-logs
make docker-clean
```

### 自定义环境配置

```bash
# 创建多环境配置文件
cp .env.example .env.dev
cp .env.example .env.prod

# 使用特定配置启动
ENV_FILE=.env.prod ./deploy.sh up
```

### CI/CD 集成

```yaml
# .github/workflows/deploy.yml
- name: Deploy to Docker
  run: |
    ./deploy.sh --env=prod --quiet up
```

---

## 🐛 故障排除

### 问题 1: Docker 守护进程未运行

```bash
# 错误信息
✗ 错误: Docker 守护进程未运行，请启动 Docker

# 解决方案
# macOS
启动 Docker Desktop

# Linux
sudo systemctl start docker
```

### 问题 2: 端口被占用

```bash
# 错误信息
Error: bind: address already in use

# 解决方案：修改 .env 配置
NGROK_HTTP_PORT=9090
NGROK_HTTPS_PORT=9443
```

### 问题 3: 镜像构建失败

```bash
# 启用调试模式查看详细日志
./deploy.sh --debug up

# 清理 Docker 缓存重试
docker system prune -a
./deploy.sh up
```

### 问题 4: 健康检查超时

```bash
# 查看容器日志
./deploy.sh logs ngrokd

# 进入容器排查
./deploy.sh exec ngrokd sh

# 检查端口监听
netstat -tlnp | grep 4443
```

---

## 📈 性能优化建议

### 1. 启用 BuildKit 加速构建

```bash
export DOCKER_BUILDKIT=1
./deploy.sh up
```

### 2. 使用多阶段构建缓存

```dockerfile
# Dockerfile 中已使用多阶段构建
FROM golang:1.19-alpine AS builder
# ... 构建
FROM alpine:3.18
# ... 运行
```

### 3. 限制日志大小

```yaml
# docker-compose.yml 中添加
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

---

## 🔒 安全最佳实践

1. **生产环境部署**
   - 修改默认端口和域名
   - 使用真实 TLS 证书
   - 启用防火墙限制访问

2. **敏感信息管理**
   - 不要将 `.env` 提交到 Git
   - 使用 Docker secrets 管理密钥
   - 定期轮换认证令牌

3. **容器安全**
   - 使用非 root 用户运行
   - 定期更新基础镜像
   - 扫描镜像漏洞

---

## 📞 获取帮助

- **脚本帮助**: `./deploy.sh --help`
- **运行测试**: `./test-deploy.sh`
- **查看日志**: `tail -f deploy.log`
- **项目文档**: `CLAUDE.md`

---

## 🎯 总结

这个部署脚本从"基础执行工具"升级为"**专业级部署助手**"，核心改进包括：

1. ✅ **环境自愈**: 自动检测依赖、生成配置、版本校验
2. ✅ **用户体验**: 颜色方案、加载动画、进度透明、帮助系统
3. ✅ **鲁棒性**: 原子操作、信号处理、防御性设计
4. ✅ **调试能力**: --debug 模式、自动日志展示、持久化日志

**开始使用**: `./deploy.sh up` 🚀
