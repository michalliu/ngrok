# 📝 deploy.sh 快速参考卡

> **一页纸速查表** - 打印或收藏备用

---

## 🚀 快速开始（3 步）

```bash
# 1️⃣ 设置权限
chmod +x deploy.sh

# 2️⃣ 一键部署
./deploy.sh up

# 3️⃣ 查看状态
./deploy.sh ps
```

---

## 📖 常用命令

| 命令 | 说明 |
|------|------|
| `./deploy.sh up` | 🚀 启动所有服务 |
| `./deploy.sh down` | 🛑 停止所有服务 |
| `./deploy.sh restart` | 🔄 重启服务 |
| `./deploy.sh ps` | 📊 查看容器状态 |
| `./deploy.sh logs` | 📋 查看所有日志 |
| `./deploy.sh logs ngrokd` | 📄 查看指定服务日志 |
| `./deploy.sh exec ngrokd sh` | 🐚 进入容器 Shell |
| `./deploy.sh clean` | 🧹 清理所有资源 |
| `./deploy.sh --help` | ❓ 显示帮助 |

---

## ⚙️ 选项参数

```bash
# 调试模式（显示详细日志）
./deploy.sh --debug up

# 生产环境部署
./deploy.sh --env=prod up

# 静默模式（减少输出）
./deploy.sh --quiet up

# 模拟执行（不实际操作）
./deploy.sh --dry-run up
```

---

## 🔧 常见操作

### 实时查看日志
```bash
./deploy.sh logs -f
./deploy.sh logs -f ngrokd
```

### 进入容器调试
```bash
./deploy.sh exec ngrokd sh
./deploy.sh exec ngrok-client sh
```

### 重启单个服务
```bash
docker-compose restart ngrokd
```

### 查看容器资源使用
```bash
docker stats
```

---

## 🐛 故障排查

### 问题: Docker 未运行
```bash
# macOS
启动 Docker Desktop

# Linux
sudo systemctl start docker
```

### 问题: 端口被占用
```bash
# 修改 .env 文件
NGROK_HTTP_PORT=9090
NGROK_HTTPS_PORT=9443
```

### 问题: 构建失败
```bash
# 清理缓存重试
docker system prune -a
./deploy.sh up
```

### 问题: 查看详细错误
```bash
# 启用调试模式
./deploy.sh --debug up

# 查看日志文件
tail -f deploy.log

# 查看容器日志
docker logs ngrokd
```

---

## 📁 重要文件

| 文件 | 用途 |
|------|------|
| `.env` | 环境变量配置 |
| `deploy.log` | 部署日志文件 |
| `docker-compose.yml` | 容器编排配置 |
| `Dockerfile` | 服务端镜像 |
| `config/ngrok-client.yml` | 客户端配置 |

---

## 🔐 环境变量（.env）

```bash
# 服务域名
NGROK_DOMAIN=ngrok.local

# 端口配置
NGROK_HTTP_PORT=8080
NGROK_HTTPS_PORT=8443
NGROK_TUNNEL_PORT=4443

# 日志级别
NGROK_LOG_LEVEL=INFO
```

---

## 🌐 访问地址

| 服务 | 地址 |
|------|------|
| HTTP | http://ngrok.local:8080 |
| HTTPS | https://ngrok.local:8443 |
| Tunnel | tcp://ngrok.local:4443 |
| Web UI | http://localhost:4040 |

---

## 📦 Docker 原生命令

### 查看容器
```bash
docker ps                    # 运行中容器
docker ps -a                 # 所有容器
docker-compose ps            # Compose 管理的容器
```

### 查看日志
```bash
docker logs ngrokd           # 完整日志
docker logs -f ngrokd        # 实时日志
docker logs --tail=50 ngrokd # 最后 50 行
```

### 进入容器
```bash
docker exec -it ngrokd sh    # 交互式 Shell
docker exec ngrokd ps aux    # 执行单个命令
```

### 清理资源
```bash
docker system prune          # 清理未使用资源
docker volume prune          # 清理卷
docker network prune         # 清理网络
```

---

## 🧪 测试与验证

### 运行测试套件
```bash
./test-deploy.sh
```

### 健康检查
```bash
# 检查容器健康状态
docker inspect --format='{{.State.Health.Status}}' ngrokd

# 检查端口监听
netstat -tlnp | grep 4443
```

### 配置验证
```bash
# 验证 docker-compose 配置
docker-compose config

# Dry-run 模式测试
./deploy.sh --dry-run up
```

---

## 🔄 更新流程

```bash
# 1. 拉取最新代码
git pull origin main

# 2. 停止服务
./deploy.sh down

# 3. 重新构建
docker-compose build --no-cache

# 4. 启动新版本
./deploy.sh up
```

---

## 📊 性能优化

### 启用 BuildKit
```bash
export DOCKER_BUILDKIT=1
./deploy.sh up
```

### 并行构建
```bash
docker-compose build --parallel
```

### 清理缓存
```bash
docker builder prune
```

---

## 🎓 使用技巧

### 1️⃣ 查看彩色日志
```bash
# deploy.sh 自带颜色编码
./deploy.sh up
# ✓ 绿色 = 成功
# ⚠ 黄色 = 警告
# ✗ 红色 = 错误
# ℹ 蓝色 = 信息
```

### 2️⃣ 后台运行并查看日志
```bash
./deploy.sh up
./deploy.sh logs -f &
```

### 3️⃣ 只重启不重新构建
```bash
./deploy.sh restart
```

### 4️⃣ 多环境管理
```bash
# 开发环境
./deploy.sh --env=dev up

# 生产环境
./deploy.sh --env=prod up
```

---

## 📞 快速帮助

| 需求 | 命令 |
|------|------|
| 脚本帮助 | `./deploy.sh --help` |
| 测试脚本 | `./test-deploy.sh` |
| 查看日志 | `tail -f deploy.log` |
| 项目文档 | `cat DEPLOY.md` |
| 技术细节 | `cat DEPLOY-TECHNICAL.md` |

---

## 🎯 记忆口诀

```
部署三步走: chmod → up → ps
调试三板斧: --debug → logs → exec
清理三件套: down → clean → prune
```

---

## 📱 快捷键（终端）

| 按键 | 功能 |
|------|------|
| `Ctrl+C` | 优雅停止脚本 |
| `Ctrl+Z` | 暂停到后台 |
| `fg` | 恢复到前台 |
| `Ctrl+L` | 清屏 |

---

## 💡 专业提示

1. **首次部署**: 耐心等待镜像构建（5-10 分钟）
2. **生产部署**: 使用 `--env=prod` 并修改默认端口
3. **调试问题**: 始终先启用 `--debug` 模式
4. **定期清理**: 每周运行 `docker system prune`
5. **备份配置**: 定期备份 `.env` 和 `docker-compose.yml`

---

## 📄 配置模板

### 最小化 .env
```bash
NGROK_DOMAIN=ngrok.local
NGROK_HTTP_PORT=8080
NGROK_HTTPS_PORT=8443
NGROK_TUNNEL_PORT=4443
```

### 生产环境 .env
```bash
ENVIRONMENT=prod
NGROK_DOMAIN=ngrok.example.com
NGROK_HTTP_PORT=80
NGROK_HTTPS_PORT=443
NGROK_TUNNEL_PORT=4443
NGROK_LOG_LEVEL=WARNING
TZ=UTC
```

---

## 🏁 检查清单

- [ ] Docker 已安装并运行
- [ ] docker-compose 已安装
- [ ] `.env` 文件已配置
- [ ] 端口未被占用
- [ ] 磁盘空间充足（> 1GB）
- [ ] deploy.sh 有执行权限

**全部勾选后执行**: `./deploy.sh up` 🚀

---

*打印此文档或保存为书签，随时查阅！*
