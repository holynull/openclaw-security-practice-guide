# OpenClaw 宿主机实例部署与安全加固指南

> **适用场景**: 在已有 Docker 容器运行的服务器上，部署独立的宿主机 OpenClaw 实例  
> **前置条件**: 服务器已通过 Docker Compose 运行 OpenClaw 容器  
> **配置时长**: 约 30-40 分钟  
> **基于版本**: OpenClaw 2026.4.5 | Security Guide v2.8

---

## 📋 部署概览

本指南将完成以下任务：
1. ✅ 安装宿主机 OpenClaw 实例（避免与 Docker 容器冲突）
2. ✅ 配置独立的状态目录和端口
3. ✅ 配置模型提供商和飞书通道
4. ✅ 部署插件（feishu-messaging）
5. ✅ 实施安全加固（权限控制、哈希基线、审计脚本）
6. ✅ 部署每日自动安全审计
7. ✅ 配置 Brain 备份（可选）

---

## 🎯 实例隔离方案

### 端口和目录规划

| 实例 | 配置目录 | Gateway 端口 | Bridge 端口 | 用途 |
|------|----------|-------------|------------|------|
| Docker 实例 1 | `~/.openclaw` | 18789 | 18790 | 主要生产环境 |
| Docker 实例 2 | `~/.openclaw2` | 28789 | 28790 | 次要/测试环境 |
| **宿主机实例** | **`~/.openclaw3`** | **38789** | - | **独立宿主机环境** |

---

## 第一阶段：基础安装

### 步骤 1: 环境检查

```bash
# 检查 Node.js 版本（要求 >= 18）
node --version

# 检查现有 OpenClaw 容器
cd ~/github.com/holynull/openclaw
docker-compose ps

# 确认端口占用情况
sudo ss -tlnp | grep -E '(18789|28789|38789)'
```

### 步骤 2: 安装 OpenClaw CLI

```bash
# 全局安装（系统级 Node.js）
sudo npm install -g openclaw@latest

# 如果使用 nvm 管理 Node.js，不要用 sudo
# npm install -g openclaw@latest

# 验证安装
openclaw --version
```

### 步骤 3: 配置独立状态目录

```bash
# 添加环境变量到 .bashrc
echo 'export OPENCLAW_STATE_DIR="$HOME/.openclaw3"' >> ~/.bashrc

# 立即生效
source ~/.bashrc

# 验证环境变量
echo $OPENCLAW_STATE_DIR
# 应输出: /home/ec2-user/.openclaw3（或你的用户目录）
```

### 步骤 4: 初始化配置

```bash
# 创建基础目录结构
mkdir -p ~/.openclaw3/{devices,workspace,logs,security-reports}

# 创建配置文件（使用独立端口 38789）
cat > ~/.openclaw3/openclaw.json << 'EOF'
{
  "meta": {
    "lastTouchedVersion": "2026.4.5",
    "lastTouchedAt": "2026-04-08T00:00:00.000Z"
  },
  "gateway": {
    "bind": "lan",
    "port": 38789
  }
}
EOF

# 创建设备配对文件
echo '{}' > ~/.openclaw3/devices/paired.json
echo '[]' > ~/.openclaw3/devices/pending.json
```

### 步骤 5: 配置模型和飞书通道

#### 5.1 创建环境变量文件

```bash
# 创建 .env 文件
cat > ~/.openclaw3/.env << 'EOF'
# OpenClaw Host Instance Environment Variables

# 模型 API 密钥
GPTSAPI_KEY=your_gptsapi_key_here
MAYNOR1024_KEY=your_maynor1024_key_here
OPENAI_API_KEY=your_openai_key_here

# 飞书配置
FEISHU_APP_ID=your_feishu_app_id
FEISHU_APP_SECRET=your_feishu_app_secret

# 其他服务（可选）
INFURA_KEY=your_infura_key_here
BRAVE_API_KEY=your_brave_api_key_here
EOF

# 设置安全权限
chmod 600 ~/.openclaw3/.env
```

> **⚠️ 重要**: 需要填写真实的 API 密钥。可以从现有 Docker 实例复制，或使用独立的密钥。

#### 5.2 更新配置文件（添加模型和通道）

```bash
cat > ~/.openclaw3/openclaw.json << 'EOF'
{
  "meta": {
    "lastTouchedVersion": "2026.4.5",
    "lastTouchedAt": "2026-04-08T00:00:00.000Z"
  },
  "browser": {
    "enabled": false
  },
  "auth": {
    "profiles": {
      "gptsapi:default": {
        "provider": "gptsapi",
        "mode": "api_key"
      },
      "maynor1024-anthropic:default": {
        "provider": "maynor1024-anthropic",
        "mode": "api_key"
      },
      "maynor1024-openai:default": {
        "provider": "maynor1024-openai",
        "mode": "api_key"
      }
    }
  },
  "models": {
    "mode": "merge",
    "providers": {
      "gptsapi": {
        "baseUrl": "https://api.gptsapi.net/v1",
        "apiKey": "${GPTSAPI_KEY}",
        "api": "openai-completions",
        "models": [
          {
            "id": "claude-sonnet-4-6",
            "name": "Claude Sonnet 4.6 via gptsapi",
            "reasoning": false,
            "input": ["text"],
            "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0},
            "contextWindow": 200000,
            "maxTokens": 8192
          },
          {
            "id": "gpt-4o",
            "name": "GPT 4o via gptsapi",
            "reasoning": false,
            "input": ["text"],
            "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0},
            "contextWindow": 128000,
            "maxTokens": 8192
          }
        ]
      },
      "maynor1024-anthropic": {
        "baseUrl": "https://apipro.maynor1024.live/v1",
        "apiKey": "${MAYNOR1024_KEY}",
        "api": "openai-completions",
        "models": [
          {
            "id": "claude-sonnet-4-6",
            "name": "Claude Sonnet 4.6 via maynor1024",
            "reasoning": false,
            "input": ["text", "image"],
            "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0},
            "contextWindow": 200000,
            "maxTokens": 8192
          },
          {
            "id": "claude-sonnet-4-5-20250929",
            "name": "Claude Sonnet 4.5 via maynor1024",
            "reasoning": false,
            "input": ["text", "image"],
            "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0},
            "contextWindow": 200000,
            "maxTokens": 8192
          }
        ]
      },
      "maynor1024-openai": {
        "baseUrl": "https://apipro.maynor1024.live/v1",
        "apiKey": "${MAYNOR1024_KEY}",
        "api": "openai-completions",
        "models": [
          {
            "id": "gpt-4o",
            "name": "GPT 4o via maynor1024",
            "reasoning": false,
            "input": ["text", "image"],
            "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0},
            "contextWindow": 128000,
            "maxTokens": 8192
          }
        ]
      },
      "openai": {
        "baseUrl": "https://api.openai.com/v1",
        "apiKey": "${OPENAI_API_KEY}",
        "api": "openai-completions",
        "models": [
          {
            "id": "gpt-4o",
            "name": "GPT-4o",
            "reasoning": false,
            "input": ["text", "image"],
            "cost": {"input": 0.0025, "output": 0.01, "cacheRead": 0, "cacheWrite": 0},
            "contextWindow": 128000,
            "maxTokens": 16384
          }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "maynor1024-openai/gpt-4o",
        "fallbacks": [
          "maynor1024-anthropic/claude-sonnet-4-6",
          "gptsapi/claude-sonnet-4-6",
          "openai/gpt-4o"
        ]
      },
      "workspace": "/home/ec2-user/.openclaw3/workspace",
      "tools": {
        "profile": "full"
      }
    }
  },
  "channels": {
    "feishu": {
      "enabled": true,
      "appId": "${FEISHU_APP_ID}",
      "appSecret": "${FEISHU_APP_SECRET}",
      "connectionMode": "websocket",
      "domain": "lark",
      "botName": "OpenClaw-Host",
      "dmPolicy": "allowlist",
      "allowFrom": [],
      "groupPolicy": "allowlist",
      "groupAllowFrom": [],
      "groups": {}
    }
  },
  "plugins": {
    "allow": [
      "feishu",
      "feishu-messaging"
    ],
    "entries": {
      "feishu": {
        "enabled": true
      },
      "feishu-messaging": {
        "enabled": true
      }
    }
  },
  "gateway": {
    "port": 38789,
    "bind": "lan",
    "mode": "local"
  }
}
EOF
```

> **说明**: 
> - 配置使用环境变量（`${VARIABLE_NAME}`）引用密钥
> - 已配置多个模型提供商和备用模型
> - 飞书通道已启用，但需要添加用户白名单
> - 插件系统已配置，支持 feishu-messaging

#### 5.3 从现有实例复制密钥（可选）

如果要使用与 Docker 实例相同的密钥：

```bash
# 查看 Docker 实例的环境变量
docker exec openclaw-cli env | grep -E "GPTSAPI_KEY|MAYNOR1024_KEY|FEISHU"

# 或者从 docker-compose 目录查看
cat ~/github.com/holynull/openclaw/.env

# 然后编辑宿主机的 .env 文件
vim ~/.openclaw3/.env
```

### 步骤 6: 部署插件

#### 6.1 创建 extensions 目录

```bash
mkdir -p ~/.openclaw3/extensions
```

#### 6.2 部署 feishu-messaging 插件

```bash
# 从本地复制插件（如果在本地机器上）
scp -r /path/to/openclaw-security-practice-guide/extensions/feishu-messaging \
  user@server:~/.openclaw3/extensions/

# 或者在服务器上直接克隆仓库并复制
cd /tmp
git clone https://github.com/holynull/openclaw-security-practice-guide.git
cp -r openclaw-security-practice-guide/extensions/feishu-messaging ~/.openclaw3/extensions/
rm -rf openclaw-security-practice-guide

# 安装插件依赖
cd ~/.openclaw3/extensions/feishu-messaging
npm install
```

#### 6.3 验证插件部署

```bash
# 检查插件文件
ls -la ~/.openclaw3/extensions/feishu-messaging/

# 应该看到：
# - index.ts (主代码)
# - openclaw.plugin.json (插件元数据)
# - package.json (依赖配置)
# - node_modules/ (依赖包)
# - README.md (使用文档)
```

> **插件功能**: feishu-messaging 提供两个工具
> - `send_feishu_reminder` - 发送飞书提醒消息（支持 @提醒、富文本）
> - `send_feishu_report` - 发送格式化报告

### 步骤 7: 部署管理脚本

从项目仓库获取预配置的管理脚本：

```bash
# 方法 1: 从 GitHub 直接下载（推荐）
curl -o ~/openclaw-host.sh https://raw.githubusercontent.com/holynull/openclaw-security-practice-guide/main/scripts/openclaw-host.sh
chmod +x ~/openclaw-host.sh

# 方法 2: 如果已克隆项目仓库
# git clone https://github.com/holynull/openclaw-security-practice-guide.git
# cp openclaw-security-practice-guide/scripts/openclaw-host.sh ~/
# chmod +x ~/openclaw-host.sh

# 验证脚本
~/openclaw-host.sh
# 应显示使用帮助
```

> **管理脚本功能**:
> - 🔧 自动加载 `.env` 环境变量（关键功能）
> - 🚀 Gateway 生命周期管理（start/stop/restart/status）
> - 🔗 设备配对管理（pair）
> - ✏️ 便捷的环境变量编辑（env）
> - 📊 完整的状态监控和端口检查
> 
> 📖 **详细文档**: [scripts/README-openclaw-host.md](../scripts/README-openclaw-host.md)

### 步骤 8: 验证基础安装

```bash
# 1. 检查目录结构
ls -la ~/.openclaw3/

# 2. 验证环境变量文件
ls -l ~/.openclaw3/.env
# 应显示: -rw------- (600)

# 3. 验证配置文件
cat ~/.openclaw3/openclaw.json | python3 -m json.tool > /dev/null && echo "JSON 格式正确 ✓"

# 4. 验证插件部署
ls -la ~/.openclaw3/extensions/feishu-messaging/
test -d ~/.openclaw3/extensions/feishu-messaging/node_modules && echo "插件依赖已安装 ✓"

# 5. 验证管理脚本
~/openclaw-host.sh
# 应显示使用帮助

# 6. 验证环境变量配置（重要！）
# 下载环境变量验证脚本
curl -o ~/.openclaw3/test-env-load.sh https://raw.githubusercontent.com/holynull/openclaw-security-practice-guide/main/scripts/test-env-load.sh

# 运行验证
bash ~/.openclaw3/test-env-load.sh
```

**环境变量验证输出说明**:
- ✅ 绿色 - 环境变量已正确设置
- ⚠️ 黄色 - 警告（变量为占位符，需要替换）
- ❌ 红色 - 错误（环境变量未设置）

> **⚠️ 下一步操作**: 如果验证脚本报告错误或警告，请编辑 `.env` 文件填写真实的 API 密钥：
> ```bash
> ~/openclaw-host.sh env
> # 编辑后重新验证
> bash ~/.openclaw3/test-env-load.sh
> ```
>
> 📖 **验证脚本文档**: [scripts/README-test-env-load.md](../scripts/README-test-env-load.md)

---

## 第二阶段：安全加固（Security Practice Guide v2.8）

> 本阶段严格遵循 OpenClaw Security Practice Guide v2.8 规范

### 步骤 1: 核心文件权限加固

```bash
export OC="$HOME/.openclaw3"

# 1.1 设置核心配置文件权限为 600（仅所有者可读写）
chmod 600 $OC/openclaw.json
chmod 600 $OC/devices/paired.json

# 1.2 验证权限
ls -l $OC/openclaw.json $OC/devices/paired.json
# 应显示: -rw------- (600)
```

> **⚠️ 重要**: 不要对这些文件使用 `chattr +i`，Gateway 运行时需要读写

### 步骤 2: 建立配置文件哈希基线

```bash
# 2.1 生成配置文件哈希基线
sha256sum $OC/openclaw.json > $OC/.config-baseline.sha256

# 2.2 验证基线文件
cat $OC/.config-baseline.sha256

# 2.3 测试基线验证
sha256sum -c $OC/.config-baseline.sha256
# 应输出: openclaw.json: OK
```

> **说明**: `paired.json` 由 Gateway 频繁写入，不纳入哈希基线（避免误报）

### 步骤 3: 部署每日安全审计脚本

#### 3.1 下载审计脚本

```bash
# 创建脚本目录
mkdir -p $OC/workspace/scripts

# 下载官方审计脚本模板
curl -o $OC/workspace/scripts/nightly-security-audit.sh \
  https://raw.githubusercontent.com/holynull/openclaw-security-practice-guide/main/scripts/nightly-security-audit-v2.8.sh

# 如果无法访问 GitHub，可以手动创建（见下方模板）

# 授予执行权限
chmod +x $OC/workspace/scripts/nightly-security-audit.sh
```

#### 3.2 修改审计脚本适配宿主机环境

编辑脚本，确保使用正确的状态目录：

```bash
vim $OC/workspace/scripts/nightly-security-audit.sh

# 确认第一行环境变量设置正确：
# OC="${OPENCLAW_STATE_DIR:-$HOME/.openclaw3}"
```

#### 3.3 手动测试审计脚本

```bash
# 执行一次，确认无错误
bash $OC/workspace/scripts/nightly-security-audit.sh

# 查看生成的报告
ls -lh $OC/security-reports/
cat $OC/security-reports/report-$(date +%Y-%m-%d).txt
```

#### 3.4 创建已知问题排除配置（可选）

```bash
# 创建空的排除配置文件
cat > $OC/.security-audit-known-issues.json << 'EOF'
[]
EOF
```

排除规则示例：

```json
[
  {
    "check": "platform_audit",
    "pattern": "skill-name|keyword-pattern",
    "reason": "已确认的排除原因",
    "added": "2026-04-08"
  }
]
```

#### 3.5 锁定审计脚本（防篡改）

```bash
# 锁定脚本为只读
sudo chattr +i $OC/workspace/scripts/nightly-security-audit.sh

# 验证锁定状态
lsattr $OC/workspace/scripts/nightly-security-audit.sh
# 应显示: ----i---------
```

> **维护时解锁**: `sudo chattr -i $OC/workspace/scripts/nightly-security-audit.sh`

---

## 第三阶段：设备配对与 Gateway 启动

### 步骤 1: 配对设备

```bash
# 使用管理脚本配对
~/openclaw-host.sh pair

# 或者直接使用命令
export OPENCLAW_STATE_DIR="$HOME/.openclaw3"
openclaw device pair
```

按照提示完成配对过程：
1. 选择配对方式（Telegram/Discord/飞书等）
2. 扫描二维码或输入配对码
3. 确认设备配对成功

### 步骤 2: 启动 Gateway

```bash
# 启动 Gateway
~/openclaw-host.sh start

# 检查状态
~/openclaw-host.sh status

# 查看日志
tail -f /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log
```

### 步骤 3: 访问 Dashboard

Gateway 启动后，可以通过以下地址访问：
- 本地: `http://127.0.0.1:38789/`
- 局域网: `http://<服务器IP>:38789/`

### 步骤 4: 验证设备配对

```bash
# 查看配对的设备列表
~/openclaw-host.sh cli device list

# 查看配对文件
cat ~/.openclaw3/devices/paired.json
```

---

## 第四阶段：配置定时审计任务

### 步骤 1: 获取 Chat ID

```bash
# 查看已配对的设备信息
~/openclaw-host.sh cli device list

# 从输出中记录 chatId（数字格式）
# 例如: -1002345678901
```

### 步骤 2: 注册 Cron 任务

```bash
export OC="$HOME/.openclaw3"

# 替换以下参数：
# <your-chat-id>: 你的 chatId（从上一步获取）
# <your-channel>: telegram 或 discord 等
# <your-model>: 你偏好的模型，如 claude-sonnet-4-6

openclaw cron add \
  "bash $OC/workspace/scripts/nightly-security-audit.sh" \
  --name "nightly-security-audit-host" \
  --description "宿主机每日安全审计" \
  --cron "0 3 * * *" \
  --tz "Asia/Shanghai" \
  --session "isolated" \
  --light-context \
  --model "claude-sonnet-4-6" \
  --message "执行此命令，然后将输出总结为简洁的安全报告。用 emoji 状态指示器（🚨/⚠️/✅）列出全部 13 项。以一行汇总标题开始，显示严重/警告/正常计数。命令: bash $OC/workspace/scripts/nightly-security-audit.sh" \
  --announce \
  --channel telegram \
  --to <your-chat-id> \
  --timeout-seconds 300 \
  --thinking off
```

> **时区说明**: 
> - 中国大陆: `Asia/Shanghai` (UTC+8)
> - 新加坡: `Asia/Singapore` (UTC+8)
> - 美国东部: `America/New_York`

### 步骤 3: 验证 Cron 任务

```bash
# 列出所有定时任务
~/openclaw-host.sh cli cron list

# 记录任务 ID
# 应看到: nightly-security-audit-host
```

### 步骤 4: 测试执行

```bash
# 手动触发一次（替换 <job-id>）
~/openclaw-host.sh cli cron run --id <job-id>

# 查看执行历史
~/openclaw-host.sh cli cron runs --id <job-id>

# 等待几分钟后，检查是否收到推送通知
```

---

## 第五阶段：配置 Brain 备份（可选）

> 此步骤为可选。如果不需要远程备份，可以跳过。

### 步骤 1: 检查 Git 状态

```bash
cd ~/.openclaw3
git status
# 如果提示 "not a git repository"，继续下一步
```

### 步骤 2: 初始化 Git 仓库

```bash
cd ~/.openclaw3

# 初始化仓库
git init

# 创建 .gitignore
cat > .gitignore << 'EOF'
# 临时文件
*.tmp
*.lock
*.sock
*.pid

# 日志
logs/
*.log

# 媒体资源
media/

# 设备临时文件
devices/*.tmp

# 审计报告（本地保留即可）
security-reports/

# Node modules
node_modules/

# 排除系统文件
.DS_Store
EOF

# 配置 Git 用户信息（如果未配置）
git config user.name "Your Name"
git config user.email "your.email@example.com"

# 添加并提交
git add .
git commit -m "Initial OpenClaw host instance state backup"
```

### 步骤 3: 添加远程仓库

```bash
# 添加你的私有 Git 仓库（需提前在 GitHub/GitLab 创建）
git remote add origin <your-private-repo-url>

# 推送到远程
git push -u origin main
```

### 步骤 4: 配置自动备份

审计脚本默认包含 Git 自动推送逻辑。如果需要独立的备份任务：

```bash
# 创建独立的备份脚本
cat > ~/openclaw-host-backup.sh << 'EOF'
#!/bin/bash
cd "$HOME/.openclaw3"
git add .
git commit -m "Auto backup $(date +%Y-%m-%d_%H:%M:%S)" || true
git push origin main
EOF

chmod +x ~/openclaw-host-backup.sh

# 测试备份
~/openclaw-host-backup.sh
```

---

## ✅ 部署完成检查清单

```bash
# === 基础安装检查 ===

# 1. 验证 OpenClaw 版本
openclaw --version
# 预期: OpenClaw 2026.4.5 或更新版本

# 2. 验证配置目录隔离
ls -d ~/.openclaw*
# 预期: .openclaw .openclaw2 .openclaw3

# 3. 验证端口隔离
sudo ss -tlnp | grep -E '(18789|28789|38789)'
# 预期: 看到三个不同的端口监听

# === 配置检查 ===

# 4. 验证环境变量文件
ls -l ~/.openclaw3/.env
# 预期: -rw------- (600)

# 5. 验证环境变量已填写
grep -E "^[A-Z_]+=" ~/.openclaw3/.env | grep -v "your_.*_here" | wc -l
# 预期: > 0 (表示已填写真实密钥)

# 6. 验证插件部署
ls -la ~/.openclaw3/extensions/feishu-messaging/index.ts
test -d ~/.openclaw3/extensions/feishu-messaging/node_modules && echo "✓ 插件依赖已安装"

# 7. 验证配置文件格式
cat ~/.openclaw3/openclaw.json | python3 -m json.tool > /dev/null && echo "✓ JSON 格式正确"

# 8. 验证模型配置
cat ~/.openclaw3/openclaw.json | grep -q "maynor1024-openai/gpt-4o" && echo "✓ 模型已配置"

# 9. 验证飞书通道
cat ~/.openclaw3/openclaw.json | grep -q '"feishu"' && echo "✓ 飞书通道已配置"

# 10. 验证插件启用
cat ~/.openclaw3/openclaw.json | grep -q '"feishu-messaging"' && echo "✓ 插件已启用"

# === 安全加固检查 ===

# 11. 验证核心文件权限
ls -l ~/.openclaw3/openclaw.json ~/.openclaw3/devices/paired.json ~/.openclaw3/.env
# 预期: -rw------- (600)

# 12. 验证哈希基线
sha256sum -c ~/.openclaw3/.config-baseline.sha256
# 预期: openclaw.json: OK

# 13. 验证审计脚本锁定
lsattr ~/.openclaw3/workspace/scripts/nightly-security-audit.sh
# 预期: ----i--------- (带 i 标志)

# === 功能检查 ===

# 14. 验证 Gateway 运行
~/openclaw-host.sh status
# 预期: Runtime: running

# 15. 验证设备配对
~/openclaw-host.sh cli device list
# 预期: 显示已配对的设备

# 16. 验证 Cron 任务
~/openclaw-host.sh cli cron list
# 预期: 看到 nightly-security-audit-host

# 17. 验证审计报告
ls -lh ~/.openclaw3/security-reports/
# 预期: 至少有一个报告文件

# === 可选检查 ===

# 18. 验证 Git 备份（如果配置）
cd ~/.openclaw3 && git status
# 预期: 显示 Git 仓库状态

# 19. 验证插件工具可用（需要 Gateway 运行）
# 在飞书中测试: "请使用 send_feishu_reminder 发送测试消息"
```

---

## 📊 日常运维

### 查看实例状态

```bash
# 查看宿主机实例状态
~/openclaw-host.sh status

# 查看所有实例对比
echo "=== Docker 实例 1 ==="
docker exec openclaw-cli openclaw gateway status

echo "=== Docker 实例 2 ==="
docker exec openclaw-cli-2 openclaw gateway status

echo "=== 宿主机实例 ==="
~/openclaw-host.sh status
```

### 查看审计报告

```bash
# 查看最新报告
cat $(ls -t ~/.openclaw3/security-reports/report-*.txt | head -1)

# 查看指定日期报告
cat ~/.openclaw3/security-reports/report-2026-04-08.txt

# 查看最近 7 天的报告列表
ls -t ~/.openclaw3/security-reports/report-*.txt | head -7
```

### 审计脚本维护

```bash
# 1. 解锁脚本
sudo chattr -i ~/.openclaw3/workspace/scripts/nightly-security-audit.sh

# 2. 编辑脚本
vim ~/.openclaw3/workspace/scripts/nightly-security-audit.sh

# 3. 测试修改
bash ~/.openclaw3/workspace/scripts/nightly-security-audit.sh

# 4. 重新锁定
sudo chattr +i ~/.openclaw3/workspace/scripts/nightly-security-audit.sh
```

> Note: Unlocking/Relocking falls under Yellow Line operations and must be logged in daily memory.

### 环境变量管理

```bash
# 编辑环境变量
~/openclaw-host.sh env

# 或直接编辑
vim ~/.openclaw3/.env

# 修改后必须重启 Gateway
~/openclaw-host.sh restart

# 验证环境变量已加载
ps aux | grep openclaw | grep -v grep | awk '{print $2}' | head -1 | \
  xargs -I {} sudo cat /proc/{}/environ | tr '\0' '\n' | grep -E "GPTSAPI|MAYNOR|FEISHU"
```

### 插件管理

#### 更新现有插件

```bash
# 1. 编辑插件代码
vim ~/.openclaw3/extensions/feishu-messaging/index.ts

# 2. 如果修改了依赖
cd ~/.openclaw3/extensions/feishu-messaging
npm install

# 3. 重启 Gateway
~/openclaw-host.sh restart
```

#### 添加新插件

```bash
# 1. 复制插件到 extensions 目录
scp -r /path/to/new-plugin user@server:~/.openclaw3/extensions/

# 2. 安装依赖
cd ~/.openclaw3/extensions/new-plugin
npm install

# 3. 更新配置文件
vim ~/.openclaw3/openclaw.json
# 在 plugins.allow 和 plugins.entries 中添加插件 ID

# 4. 更新权限和基线
chmod 600 ~/.openclaw3/openclaw.json
cd ~/.openclaw3 && sha256sum openclaw.json > .config-baseline.sha256

# 5. 重启 Gateway
~/openclaw-host.sh restart
```

```bash
export OC="$HOME/.openclaw3"

# 1. 停止 Gateway
~/openclaw-host.sh stop

# 2. 升级 OpenClaw
sudo npm i -g openclaw@latest
# 如果使用 nvm: npm i -g openclaw@latest

# 3. 验证版本
openclaw --version

# 4. 启动 Gateway
~/openclaw-host.sh start

# 5. 验证运行状态
~/openclaw-host.sh status

# 6. 重建配置基线
sha256sum $OC/openclaw.json > $OC/.config-baseline.sha256

# 7. 如果安装了新 Skill，更新 Skill 基线
find $OC/workspace/skills -type f -not -path '*/.git/*' -exec sha256sum {} \; | sort | sha256sum > $OC/.skill-baseline.sha256
```

---

## 🔍 故障排查

### Gateway 无法启动

**症状**: `~/openclaw-host.sh start` 失败

**排查步骤**:

```bash
# 1. 检查端口占用
sudo ss -tlnp | grep 38789

# 2. 检查配置文件
cat ~/.openclaw3/openclaw.json

# 3. 查看错误日志
tail -100 /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log

# 4. 验证文件权限
ls -l ~/.openclaw3/openclaw.json

# 5. 重新生成配置
mv ~/.openclaw3/openclaw.json ~/.openclaw3/openclaw.json.bak
# 重新创建配置文件（参考步骤 5.2）
```

### 环境变量未生效

**症状**: API 调用失败，提示密钥无效

**排查步骤**:

```bash
# 1. 验证 .env 文件存在且可读
ls -l ~/.openclaw3/.env

# 2. 检查环境变量内容
cat ~/.openclaw3/.env | grep -v "^#" | grep "="

# 3. 确认密钥已填写
grep -E "your_.*_here" ~/.openclaw3/.env
# 不应有输出，表示已替换所有占位符

# 4. 检查 Gateway 进程的环境变量
ps aux | grep openclaw-gateway | grep -v grep | awk '{print $2}' | head -1 | \
  xargs -I {} sudo cat /proc/{}/environ | tr '\0' '\n' | grep GPTSAPI_KEY

# 5. 重启 Gateway 重新加载环境变量
~/openclaw-host.sh restart
```

### 插件工具不可用

**症状**: Agent 无法调用 send_feishu_reminder 等工具

**排查步骤**:

```bash
# 1. 检查插件文件
ls -la ~/.openclaw3/extensions/feishu-messaging/

# 2. 验证插件依赖已安装
test -d ~/.openclaw3/extensions/feishu-messaging/node_modules && \
  echo "✓ 依赖已安装" || echo "✗ 依赖缺失"

# 3. 检查插件配置
cat ~/.openclaw3/openclaw.json | python3 -m json.tool | grep -A 10 "plugins"

# 4. 验证 tools 配置
cat ~/.openclaw3/openclaw.json | python3 -m json.tool | grep -A 5 '"tools"'

# 5. 查看 Gateway 日志
tail -100 /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log | grep -i "plugin\|extension"

# 6. 重新安装插件依赖
cd ~/.openclaw3/extensions/feishu-messaging
rm -rf node_modules package-lock.json
npm install

# 7. 重启 Gateway
~/openclaw-host.sh restart
```

### Cron 任务未执行

**症状**: 未收到每日审计通知

**排查步骤**:

```bash
# 1. 检查任务列表
~/openclaw-host.sh cli cron list

# 2. 查看执行历史
~/openclaw-host.sh cli cron runs --id <job-id>

# 3. 手动执行测试
~/openclaw-host.sh cli cron run --id <job-id>

# 4. 检查 Gateway 状态
~/openclaw-host.sh status

# 5. 查看本地报告（即使推送失败，报告也会保存）
cat ~/.openclaw3/security-reports/report-$(date +%Y-%m-%d).txt
```

### 审计报告未推送

**可能原因**:
- Telegram/Discord API 临时故障
- chatId 不正确
- 超时（脚本执行时间 > 300秒）

**解决方案**:

```bash
# 1. 验证 chatId
~/openclaw-host.sh cli device list

# 2. 查看本地报告（始终保存）
cat ~/.openclaw3/security-reports/report-$(date +%Y-%m-%d).txt

# 3. 调整超时时间
~/openclaw-host.sh cli cron edit --id <job-id> --timeout-seconds 600

# 4. 手动触发测试
~/openclaw-host.sh cli cron run --id <job-id>
```

### 基线验证失败

**症状**: `sha256sum -c` 报告不匹配

**排查步骤**:

```bash
# 1. 查看具体差异
sha256sum ~/.openclaw3/openclaw.json
cat ~/.openclaw3/.config-baseline.sha256

# 2. 如果是合法变更（如配置更新），重建基线
sha256sum ~/.openclaw3/openclaw.json > ~/.openclaw3/.config-baseline.sha256

# 3. 如果是异常变更，检查修改历史
# 查看最近的 sudo 操作
sudo grep -E 'openclaw|~/.openclaw3' /var/log/auth.log | tail -50
```

### 环境变量未生效

**症状**: 命令找不到配置目录

**解决方案**:

```bash
# 1. 重新加载 bashrc
source ~/.bashrc

# 2. 验证环境变量
echo $OPENCLAW_STATE_DIR

# 3. 如果仍未生效，手动设置
export OPENCLAW_STATE_DIR="$HOME/.openclaw3"

# 4. 或者使用管理脚本（自动设置环境变量）
~/openclaw-host.sh cli <命令>
```

---

## 🔐 安全最佳实践

### 1. 访问控制

```bash
# 限制 SSH 访问（如果需要）
sudo vim /etc/ssh/sshd_config
# 设置: AllowUsers ec2-user

# 配置防火墙（如果需要外网访问 Dashboard）
sudo ufw allow 38789/tcp comment 'OpenClaw Host Gateway'
```

### 2. 定期审查

- **每周**: 查看审计报告，确认无异常
- **每月**: 检查 Skill/MCP 更新，评估安全性
- **每季度**: 全面审查配置和访问权限

### 3. 密钥管理

- 不要在配置文件中明文存储敏感信息
- 使用环境变量或密钥管理服务
- 定期轮换 API 密钥和访问令牌

### 4. 备份验证

```bash
# 定期验证备份完整性
cd ~/.openclaw3
git log --oneline | head -10

# 测试恢复流程（在测试环境）
git clone <your-repo> /tmp/openclaw-restore-test
```

---

## 📚 相关文档

### 核心指南
- [OpenClaw Security Practice Guide v2.8](./OpenClaw-Security-Practice-Guide-v2.8.md) - 完整安全实践指南
- [OpenClaw 极简安全实践指南 v2.8](./OpenClaw极简安全实践指南v2.8.md) - 中文完整版
- [AWS Linux Configuration Steps](./AWS-Linux-Configuration-Steps-zh.md) - AWS 环境配置
- [Validation Guide](./Validation-Guide-zh.md) - 验证指南

### 工具文档
- [宿主机管理脚本文档](../scripts/README-openclaw-host.md) - openclaw-host.sh 使用指南
- [环境变量验证脚本文档](../scripts/README-test-env-load.md) - test-env-load.sh 使用指南
- [Scripts 目录总览](../scripts/README.md) - 所有脚本说明

---

## 🆘 获取帮助

### 官方资源

- OpenClaw 官方文档: https://docs.openclaw.ai
- OpenClaw GitHub: https://github.com/openclaw/openclaw
- 安全指南仓库: https://github.com/holynull/openclaw-security-practice-guide

### 社区支持

- 提交 Issue: https://github.com/holynull/openclaw-security-practice-guide/issues
- Discord/Telegram 社区（参考 OpenClaw 官网）

---

## 📝 附录

### A. 快速命令参考

```bash
# 管理脚本
~/openclaw-host.sh status     # 查看状态
~/openclaw-host.sh start      # 启动
~/openclaw-host.sh stop       # 停止
~/openclaw-host.sh restart    # 重启
~/openclaw-host.sh pair       # 配对设备
~/openclaw-host.sh cli <cmd>  # 执行命令

# 环境变量
export OPENCLAW_STATE_DIR="$HOME/.openclaw3"
export OC="$HOME/.openclaw3"

# 常用路径
~/.openclaw3/                              # 状态目录
~/.openclaw3/openclaw.json                 # 配置文件
~/.openclaw3/workspace/scripts/            # 脚本目录
~/.openclaw3/security-reports/             # 审计报告
/tmp/openclaw/openclaw-YYYY-MM-DD.log      # 日志文件
```

### B. 审计脚本模板位置

如果无法从 GitHub 下载，可以从以下位置获取：
- 项目仓库: `scripts/nightly-security-audit-v2.8.sh`
- 或者参考现有 Docker 实例的配置

### C. 端口规划参考

建议的端口分配方案：
- 10000-19999: Docker/容器服务
- 20000-29999: 开发/测试环境
- 30000-39999: 宿主机/生产服务
- 40000+: 临时/实验性服务

---

**部署完成！** 🎉

现在你拥有一个完全隔离、安全加固的宿主机 OpenClaw 实例，与 Docker 容器和平共存。
