# OpenClaw 宿主机管理脚本

> **openclaw-host.sh** - 统一管理 OpenClaw 宿主机实例的启动、配置和环境变量

## 📋 概述

`openclaw-host.sh` 是一个便捷的 Shell 脚本，用于管理 OpenClaw 宿主机实例。它自动加载环境变量，提供统一的管理接口，避免手动设置环境变量的繁琐操作。

## 🎯 核心功能

### ✅ 主要特性

1. **自动环境变量加载**
   - 启动时自动加载 `$OPENCLAW_STATE_DIR/.env`
   - 使用 `set -a` 确保变量传递给子进程
   - 避免每次手动 `export` 的麻烦

2. **实例生命周期管理**
   - 启动/停止/重启 Gateway
   - 查看运行状态和资源使用
   - 端口冲突检测

3. **设备管理**
   - 便捷的设备配对命令
   - 设备列表查询

4. **配置管理**
   - 快捷编辑 `.env` 文件
   - 配置变更后自动提示重启

5. **多实例支持**
   - 通过修改 `OPENCLAW_STATE_DIR` 支持多实例
   - 适用于同一服务器运行多个独立实例

## 📦 安装

### 方法 1: 从项目仓库部署

```bash
# 克隆项目（如果尚未克隆）
git clone https://github.com/holynull/openclaw-security-practice-guide.git

# 复制到服务器
scp openclaw-security-practice-guide/scripts/openclaw-host.sh user@server:~/

# 登录服务器设置权限
ssh user@server
chmod +x ~/openclaw-host.sh
```

### 方法 2: 直接创建

在服务器上直接创建脚本：

```bash
vim ~/openclaw-host.sh
# 粘贴脚本内容
chmod +x ~/openclaw-host.sh
```

### 验证安装

```bash
~/openclaw-host.sh
# 应显示帮助信息
```

## 🚀 使用方法

### 基础命令

```bash
# 查看帮助
~/openclaw-host.sh

# 启动 Gateway
~/openclaw-host.sh start

# 停止 Gateway
~/openclaw-host.sh stop

# 重启 Gateway
~/openclaw-host.sh restart

# 查看状态
~/openclaw-host.sh status
```

### 设备管理

```bash
# 配对新设备
~/openclaw-host.sh pair

# 查看已配对设备
~/openclaw-host.sh cli device list

# 查看设备详情
~/openclaw-host.sh cli device show <device-id>
```

### 环境变量管理

```bash
# 编辑环境变量
~/openclaw-host.sh env
# 会用 vim 打开 ~/.openclaw3/.env
# 保存退出后，脚本会提示重启

# 查看当前环境变量（调试用）
~/openclaw-host.sh cli config show
```

### 执行任意 OpenClaw 命令

```bash
# 语法
~/openclaw-host.sh cli <openclaw-command>

# 示例
~/openclaw-host.sh cli gateway status
~/openclaw-host.sh cli cron list
~/openclaw-host.sh cli plugin list
~/openclaw-host.sh cli channel list
```

## 📊 状态查看详解

运行 `~/openclaw-host.sh status` 会显示：

```
=== OpenClaw Host Instance Status ===
State Dir: /home/ec2-user/.openclaw3
Gateway Port: 38789

Gateway: openclaw/gateway-2026.4.5
Runtime: running

=== All OpenClaw Processes ===
ec2-user  12345  0.5  1.2  1234567  123456 ?  Ssl  10:00   0:05 node /usr/local/bin/openclaw gateway

=== Port Usage ===
LISTEN  0   128   0.0.0.0:18789   0.0.0.0:*   users:(("node",pid=11111,fd=20))
LISTEN  0   128   0.0.0.0:28789   0.0.0.0:*   users:(("node",pid=22222,fd=20))
LISTEN  0   128   0.0.0.0:38789   0.0.0.0:*   users:(("node",pid=33333,fd=20))
```

## ⚙️ 配置

### 默认配置

脚本默认配置：

```bash
OPENCLAW_STATE_DIR="$HOME/.openclaw3"  # 状态目录
Gateway Port: 38789                     # Gateway 端口
```

### 自定义配置

如需管理不同的实例，修改脚本中的 `OPENCLAW_STATE_DIR`：

```bash
# 编辑脚本
vim ~/openclaw-host.sh

# 修改这一行
export OPENCLAW_STATE_DIR="$HOME/.openclaw-custom"
```

或创建多个脚本副本：

```bash
# 为不同实例创建不同的管理脚本
cp ~/openclaw-host.sh ~/openclaw-dev.sh
cp ~/openclaw-host.sh ~/openclaw-prod.sh

# 在每个脚本中修改 OPENCLAW_STATE_DIR
```

## 🔧 工作原理

### 环境变量加载机制

脚本使用以下方式加载环境变量：

```bash
if [ -f "$OPENCLAW_STATE_DIR/.env" ]; then
  set -a                          # 标记所有变量为 export
  source "$OPENCLAW_STATE_DIR/.env"  # 加载 .env 文件
  set +a                          # 取消自动 export
fi
```

**关键点**:
- `set -a`: 使所有后续定义的变量自动 export
- `source .env`: 加载环境变量文件
- `set +a`: 恢复正常模式
- 所有变量会传递给 `openclaw` 子进程

### 命令执行流程

```
用户命令
    ↓
openclaw-host.sh
    ↓
加载 .env 环境变量
    ↓
执行 openclaw 命令 (继承环境变量)
    ↓
返回结果
```

## 🛠️ 故障排查

### 问题 1: 启动失败

**症状**: `~/openclaw-host.sh start` 后 Gateway 未运行

**诊断**:
```bash
# 查看日志
cat ~/.openclaw3/logs/gateway.log

# 检查端口占用
sudo ss -tlnp | grep 38789

# 检查配置文件
cat ~/.openclaw3/openclaw.json
```

**常见原因**:
- 端口被占用 → 修改端口或停止冲突进程
- 配置文件语法错误 → 验证 JSON 格式
- 环境变量缺失 → 运行 `test-env-load.sh` 验证

### 问题 2: 环境变量未生效

**症状**: 启动后模型连接失败，提示 API Key 错误

**诊断**:
```bash
# 验证环境变量
bash ~/.openclaw3/test-env-load.sh

# 检查 .env 文件
cat ~/.openclaw3/.env

# 测试环境变量加载（手动）
set -a
source ~/.openclaw3/.env
set +a
echo $GPTSAPI_KEY  # 应显示 API Key
```

**解决方法**:
1. 确保 `.env` 文件存在且权限正确（600）
2. 确保环境变量没有占位符（如 `YOUR_KEY_HERE`）
3. 使用 `~/openclaw-host.sh restart` 重启服务
4. 永远使用管理脚本，而不是直接运行 `openclaw` 命令

### 问题 3: 命令找不到

**症状**: `openclaw: command not found`

**解决**:
```bash
# 检查 OpenClaw 是否安装
which openclaw

# 如未安装，全局安装
npm install -g @openclaw/cli

# 验证版本
openclaw --version
```

### 问题 4: 权限错误

**症状**: Permission denied 错误

**解决**:
```bash
# 确保脚本可执行
chmod +x ~/openclaw-host.sh

# 确保 .env 文件权限正确
chmod 600 ~/.openclaw3/.env

# 确保状态目录权限正确
chmod 700 ~/.openclaw3
```

## 📚 相关文档

- [宿主机部署指南](../docs/Host-Instance-Deployment-Guide-zh.md) - 完整的部署流程
- [环境变量测试脚本](./README-test-env-load.md) - 环境变量验证工具
- [安全实践指南 v2.8](../docs/OpenClaw-Security-Practice-Guide-v2.8.md) - 安全配置最佳实践
- [Scripts 目录说明](./README.md) - 所有脚本总览

## 💡 最佳实践

1. **始终使用管理脚本**
   ```bash
   # ✅ 正确 - 通过管理脚本
   ~/openclaw-host.sh start
   
   # ❌ 错误 - 直接调用（环境变量不会加载）
   openclaw gateway start
   ```

2. **配置变更后重启**
   ```bash
   ~/openclaw-host.sh env    # 编辑配置
   ~/openclaw-host.sh restart  # 重启生效
   ```

3. **定期检查状态**
   ```bash
   # 加入 cron 每小时检查
   0 * * * * ~/openclaw-host.sh status >> /var/log/openclaw-status.log
   ```

4. **保护脚本安全**
   ```bash
   # 确保只有用户可执行
   chmod 700 ~/openclaw-host.sh
   
   # 记录 sha256 基线
   sha256sum ~/openclaw-host.sh > ~/openclaw-host.sh.sha256
   ```

5. **多实例隔离**
   ```bash
   # 为不同环境创建独立脚本
   cp openclaw-host.sh openclaw-dev.sh   # 开发环境
   cp openclaw-host.sh openclaw-prod.sh  # 生产环境
   
   # 修改各自的 OPENCLAW_STATE_DIR
   ```

## 🔐 安全注意事项

1. **.env 文件权限**: 必须设置为 600（仅所有者可读写）
2. **脚本权限**: 推荐设置为 700（仅所有者可执行）
3. **日志文件**: 定期清理日志，防止泄露敏感信息
4. **端口隔离**: 使用防火墙限制 Gateway 端口访问
5. **基线校验**: 定期验证脚本 sha256，防止篡改

## 🆘 获取帮助

- **GitHub Issues**: https://github.com/holynull/openclaw-security-practice-guide/issues
- **OpenClaw 文档**: https://docs.openclaw.ai
- **社区讨论**: OpenClaw Discord/Slack

---

**作者**: holynull  
**版本**: 1.0  
**最后更新**: 2026-04-08
