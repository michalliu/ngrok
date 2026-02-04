# ⚡ ngrok Docker 部署 - 5 分钟快速上手

## 🚀 一键启动（3 个命令）

```bash
# 1️⃣ 赋予执行权限
chmod +x deploy.sh

# 2️⃣ 启动所有服务
./deploy.sh up

# 3️⃣ 查看运行状态
./deploy.sh ps
```

**就这么简单！** 🎉

---

## 📊 运行效果预览

### 启动过程
```bash
$ ./deploy.sh up

ℹ 启动 ngrok 部署流程...

▸ [1/5] 环境依赖检测
✓ 所有依赖检查通过

▸ [2/5] 构建 Docker 镜像
⠋  正在构建镜像...
✓ 镜像构建成功

▸ [3/5] 启动服务容器
✓ 服务启动成功

▸ [4/5] 健康检查
[████████████████████████░░░░░░] 80%
✓ 所有服务健康检查通过

▸ [5/5] 部署状态

容器状态:
NAME           IMAGE            STATUS         PORTS
ngrokd         ngrok/server     Up 5 seconds   0.0.0.0:8080->80/tcp...

访问地址:
  • HTTP:   http://ngrok.local:8080
  • HTTPS:  https://ngrok.local:8443
  • Tunnel: tcp://ngrok.local:4443

✓ 部署完成！🎉
```

---

## 🌐 配置本地访问

### macOS / Linux
```bash
# 添加域名解析
echo "127.0.0.1 ngrok.local" | sudo tee -a /etc/hosts

# 访问服务
curl http://ngrok.local:8080
```

### Windows
```powershell
# 编辑 C:\Windows\System32\drivers\etc\hosts
# 添加一行：
127.0.0.1 ngrok.local
```

---

## 📖 常用命令

```bash
# 查看帮助
./deploy.sh --help

# 查看日志
./deploy.sh logs

# 重启服务
./deploy.sh restart

# 停止服务
./deploy.sh down

# 进入容器
./deploy.sh exec ngrokd sh

# 清理所有资源
./deploy.sh clean
```

---

## 🐛 遇到问题？

### Docker 未运行
```bash
# macOS
启动 Docker Desktop

# Linux
sudo systemctl start docker
```

### 端口被占用
```bash
# 修改 .env 文件中的端口
vim .env
# 更改：NGROK_HTTP_PORT=9090
```

### 查看详细错误
```bash
# 启用调试模式
./deploy.sh --debug up

# 查看日志文件
tail -f deploy.log
```

---

## 📚 进一步学习

| 文档 | 用途 | 阅读时间 |
|------|------|----------|
| `DEPLOY-CHEATSHEET.md` | 快速参考卡 | 2 分钟 |
| `DEPLOY.md` | 完整部署指南 | 10 分钟 |
| `README.Docker.md` | Docker 部署总览 | 15 分钟 |
| `DEPLOY-TECHNICAL.md` | 技术架构详解 | 30 分钟 |

---

## ✨ 核心特性

- ✅ **自动环境检测** - 自动检查 Docker、docker-compose 依赖
- ✅ **彩色输出** - 成功（绿）、警告（黄）、错误（红）
- ✅ **加载动画** - Spinner 和进度条可视化
- ✅ **智能修复** - 缺少配置文件自动生成
- ✅ **优雅降级** - 构建失败不影响现有容器
- ✅ **完整文档** - 5 级文档体系，随时查阅

---

## 🎯 下一步

### 开发环境
```bash
# 配置环境变量
vim .env

# 启动服务
./deploy.sh up

# 开始开发！
```

### 生产环境
```bash
# 使用生产配置
./deploy.sh --env=prod up

# 查看运行状态
./deploy.sh ps
```

### 运行测试
```bash
# 运行测试套件
./test-deploy.sh
```

---

## 💡 专业提示

1. **首次启动**: 镜像构建需要 5-10 分钟，请耐心等待
2. **调试问题**: 始终先启用 `--debug` 模式查看详细日志
3. **定期清理**: 每周运行 `docker system prune` 清理未使用资源
4. **备份配置**: 定期备份 `.env` 文件

---

## 📞 快速帮助

```bash
./deploy.sh --help          # 查看帮助
./test-deploy.sh            # 运行测试
tail -f deploy.log          # 查看日志
```

---

**就这么简单！开始使用吧！** 🚀

*需要更多帮助？查看 `DEPLOY.md` 获取完整文档。*
