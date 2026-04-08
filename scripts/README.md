# Scripts 目录

OpenClaw 安全实践指南的脚本集合。

## 📜 脚本列表

### 1. 安全审计脚本

#### nightly-security-audit-v2.8.sh

**用途**: OpenClaw 每日安全审计脚本（v2.8）

**功能**:
- 执行 13 项全面的安全检查
- 生成详细的安全报告
- 支持已知问题排除列表
- 输出摘要到标准输出供 LLM 处理

**使用**:
```bash
# 手动执行
bash $OC/workspace/scripts/nightly-security-audit.sh

# 通过 Cron 定时执行（推荐）
openclaw cron add "bash $OC/workspace/scripts/nightly-security-audit.sh" \
  --name "nightly-security-audit" \
  --cron "0 3 * * *" \
  --tz "Asia/Shanghai" \
  ...
```

**报告位置**: `$OC/security-reports/report-YYYY-MM-DD.txt`

**文档**: 详见 [OpenClaw Security Practice Guide v2.8](../docs/OpenClaw-Security-Practice-Guide-v2.8.md)

---

#### nightly-security-audit.sh

**用途**: OpenClaw 每日安全审计脚本（早期版本）

**状态**: 建议使用 v2.8 版本

---

### 2. 环境变量测试脚本

#### test-env-load.sh

**用途**: 验证 OpenClaw 环境变量配置是否正确

**功能**:
- ✅ 检查 `.env` 文件是否存在
- ✅ 验证必要的环境变量是否已设置
- ✅ 检测占位符是否已替换为真实值
- ✅ 测试子进程是否能继承环境变量
- ✅ 提供详细的错误报告和修复建议

**使用**:
```bash
# 在服务器上运行
bash ~/.openclaw3/test-env-load.sh

# 或从本地运行
OPENCLAW_STATE_DIR=~/.openclaw3 bash scripts/test-env-load.sh
```

**退出码**:
- `0` - 所有配置正确
- `1` - 发现错误（环境变量未设置）
- `2` - 发现警告（环境变量为占位符）

**文档**: [README-test-env-load.md](./README-test-env-load.md)

---

### 3. 宿主机管理脚本

#### openclaw-host.sh

**用途**: 管理宿主机 OpenClaw 实例的启动、停止和配置

**功能**:
- 🚀 管理 Gateway 生命周期（start/stop/restart）
- 🔧 自动加载 `.env` 环境变量
- 📊 查看实例状态和端口使用情况
- 🔗 设备配对管理
- ✏️ 便捷的环境变量编辑

**安装**:
```bash
# 复制到服务器
scp scripts/openclaw-host.sh user@server:~/openclaw-host.sh

# 设置执行权限
ssh user@server "chmod +x ~/openclaw-host.sh"
```

**使用**:
```bash
# 启动 Gateway
~/openclaw-host.sh start

# 查看状态
~/openclaw-host.sh status

# 重启服务
~/openclaw-host.sh restart

# 配对设备
~/openclaw-host.sh pair

# 编辑环境变量
~/openclaw-host.sh env

# 执行 openclaw 命令
~/openclaw-host.sh cli device list
~/openclaw-host.sh cli gateway status
```

**环境变量**:
- `OPENCLAW_STATE_DIR`: 默认 `~/.openclaw3`
- 自动加载 `$OPENCLAW_STATE_DIR/.env` 中的所有变量

**特性**:
- ✅ 启动前自动加载环境变量
- ✅ 统一的实例管理接口
- ✅ 端口冲突检测（18789/28789/38789）
- ✅ 支持多实例部署（通过修改 `OPENCLAW_STATE_DIR`）

**文档**: [README-openclaw-host.md](./README-openclaw-host.md) | [宿主机部署指南](../docs/Host-Instance-Deployment-Guide-zh.md)

---

### 4. Cron 任务消息模板

#### cron-messages/nightly-security-audit.md

**用途**: OpenClaw Cron 任务的消息模板（安全审计）

**功能**:
- 📋 定义审计任务的执行步骤
- 🔧 配置飞书报告发送逻辑
- 📊 规范报告格式和内容
- 🎯 使用 feishu-messaging 插件发送报告

**部署位置**:
```bash
~/.openclaw3/workspace/team/cron_messages/nightly-security-audit.md
```

**使用方式**:
```bash
# 1. 复制模板到服务器
scp scripts/cron-messages/nightly-security-audit.md \
    user@server:~/.openclaw3/workspace/team/cron_messages/

# 2. 编辑文件，替换飞书群组 ID
ssh user@server "vim ~/.openclaw3/workspace/team/cron_messages/nightly-security-audit.md"

# 3. 注册 Cron 任务
openclaw cron add "nightly-security-audit-host" \
  --message "Read cron_messages/nightly-security-audit.md and execute all steps" \
  --cron "0 3 * * *" \
  ...
```

**优势**:
- ✅ 任务逻辑与 Cron 配置分离
- ✅ 易于维护和更新（无需重建 Cron 任务）
- ✅ 支持复杂的多步骤任务
- ✅ 可复用的模板结构

**文档**: 参考 [宿主机部署指南 - 第四阶段](../docs/Host-Instance-Deployment-Guide-zh.md)

---

## 🚀 快速开始

### 部署安全审计

```bash
# 1. 复制审计脚本到服务器
scp scripts/nightly-security-audit-v2.8.sh user@server:~/.openclaw3/workspace/scripts/

# 2. 设置执行权限
ssh user@server "chmod +x ~/.openclaw3/workspace/scripts/nightly-security-audit-v2.8.sh"

# 3. 测试执行
ssh user@server "bash ~/.openclaw3/workspace/scripts/nightly-security-audit-v2.8.sh"

# 4. 锁定脚本
ssh user@server "sudo chattr +i ~/.openclaw3/workspace/scripts/nightly-security-audit-v2.8.sh"

# 5. 注册定时任务
ssh user@server "openclaw cron add ..."
```

### 验证环境变量配置

```bash
# 1. 复制测试脚本
scp scripts/test-env-load.sh user@server:~/.openclaw3/

# 2. 运行测试
ssh user@server "bash ~/.openclaw3/test-env-load.sh"

# 3. 根据输出修复问题
# 如果报错，按提示修改 .env 文件
```

### 部署宿主机管理脚本

```bash
# 1. 复制管理脚本到服务器
scp scripts/openclaw-host.sh user@server:~/openclaw-host.sh

# 2. 设置执行权限
ssh user@server "chmod +x ~/openclaw-host.sh"

# 3. 验证环境变量
ssh user@server "bash ~/.openclaw3/test-env-load.sh"

# 4. 启动实例
ssh user@server "~/openclaw-host.sh start"

# 5. 检查状态
ssh user@server "~/openclaw-host.sh status"

# 6. 配对设备
ssh user@server "~/openclaw-host.sh pair"
```

## 📂 目录结构

```
scripts/
├── README.md                          # 本文件
├── README-test-env-load.md            # 环境变量测试脚本文档
├── README-openclaw-host.md            # 宿主机管理脚本文档
├── nightly-security-audit-v2.8.sh     # 安全审计脚本 v2.8
├── nightly-security-audit.sh          # 安全审计脚本（早期版本）
├── test-env-load.sh                   # 环境变量加载测试脚本
├── openclaw-host.sh                   # 宿主机实例管理脚本
└── cron-messages/                     # Cron 任务消息模板目录
    └── nightly-security-audit.md      # 安全审计任务模板
```

## 🔐 安全注意事项

1. **审计脚本锁定**: 部署后使用 `sudo chattr +i` 锁定，防止篡改
2. **环境变量权限**: `.env` 文件必须设置为 600 权限
3. **敏感信息**: 测试脚本只显示密钥的前 10 个字符
4. **日志审查**: 定期检查安全报告，关注异常

## 📚 相关文档

- [OpenClaw Security Practice Guide v2.8](../docs/OpenClaw-Security-Practice-Guide-v2.8.md)
- [宿主机部署指南](../docs/Host-Instance-Deployment-Guide-zh.md)
- [AWS Linux 配置步骤](../docs/AWS-Linux-Configuration-Steps-zh.md)

## 🆘 获取帮助

- 提交 Issue: https://github.com/holynull/openclaw-security-practice-guide/issues
- OpenClaw 官方文档: https://docs.openclaw.ai

---

**维护者**: holynull  
**更新日期**: 2026-04-08
