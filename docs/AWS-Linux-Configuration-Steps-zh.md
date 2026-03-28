# OpenClaw 安全配置步骤（AWS Linux）

> **适用环境**: AWS Linux 服务器，OpenClaw 已预装  
> **配置时长**: 约 15-20 分钟  
> **前置要求**: 具备 SSH 访问权限，了解基本 Linux 命令

---

## 📋 配置概览

本配置步骤将完成以下安全加固：
- 核心配置文件权限控制
- 配置文件哈希基线建立
- 每日自动化安全审计部署
- Brain 备份配置（可选）

---

## 🚀 快速配置步骤

### 前置检查

1. **确认 OpenClaw 安装状态**
```bash
# 检查版本
openclaw --version

# 检查 Gateway 状态
systemctl --user is-active openclaw-gateway
# 或者
openclaw gateway status
```

2. **确认状态目录**
```bash
# 设置环境变量（如果未设置）
export OC="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
echo "OpenClaw 状态目录: $OC"

# 验证目录存在
ls -la $OC/
```

---

### 步骤 1: 核心文件权限加固

```bash
# 1.1 限制核心配置文件权限（仅当前用户可读写）
chmod 600 $OC/openclaw.json
chmod 600 $OC/devices/paired.json

# 1.2 验证权限设置
ls -l $OC/openclaw.json
ls -l $OC/devices/paired.json
# 应显示: -rw------- (600)
```

> **⚠️ 注意**: 不要对这些文件使用 `chattr +i` 锁定，因为 Gateway 运行时需要读写这些文件

---

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

---

### 步骤 3: 部署每日安全审计脚本

#### 3.1 创建审计脚本

```bash
# 创建脚本目录
mkdir -p $OC/workspace/scripts

# 下载审计脚本（使用官方模板）
curl -o $OC/workspace/scripts/nightly-security-audit.sh \
  https://raw.githubusercontent.com/holynull/openclaw-security-practice-guide/main/scripts/nightly-security-audit-v2.8.sh

# 授予执行权限
chmod +x $OC/workspace/scripts/nightly-security-audit.sh
```

> **替代方案**: 如果无法访问 GitHub，可以手动创建脚本文件，参考本文档附录部分

#### 3.2 测试审计脚本

```bash
# 手动执行一次，确认无错误
bash $OC/workspace/scripts/nightly-security-audit.sh

# 查看生成的报告
ls -lh $OC/security-reports/
cat $OC/security-reports/report-$(date +%Y-%m-%d).txt
```

#### 3.3 配置已知问题排除列表（可选）

如果已知某些检测项会产生误报，可以创建排除配置：

```bash
# 创建排除配置文件
cat > $OC/.security-audit-known-issues.json << 'EOF'
[]
EOF
```

> **说明**: 运行一段时间后，如果发现确认的误报，可以按以下格式添加排除规则：

```json
[
  {
    "check": "platform_audit",
    "pattern": "skill-name|keyword-pattern",
    "reason": "已确认的排除原因",
    "added": "2026-03-28"
  }
]
```

#### 3.4 锁定审计脚本（防篡改）

```bash
# 锁定脚本为只读
sudo chattr +i $OC/workspace/scripts/nightly-security-audit.sh

# 验证锁定状态
lsattr $OC/workspace/scripts/nightly-security-audit.sh
# 应显示: ----i---------
```

> **解锁方法**（需要更新脚本时）:
> ```bash
> sudo chattr -i $OC/workspace/scripts/nightly-security-audit.sh
> # 修改脚本...
> sudo chattr +i $OC/workspace/scripts/nightly-security-audit.sh
> ```

---

### 步骤 4: 注册定时审计任务

#### 4.1 获取当前聊天 ID

```bash
# 在 OpenClaw 中执行（或询问 Agent）
openclaw device list
# 记录你的设备对应的 chatId
```

#### 4.2 注册 Cron 任务

```bash
# 替换以下参数：
# - <your-chat-id>: 你的聊天 ID（数字格式）
# - <your-channel>: telegram 或 discord 等
# - <your-model>: 你偏好的模型，如 gpt-4o 或 claude-3-5-sonnet-20241022

openclaw cron add \
  "bash $OC/workspace/scripts/nightly-security-audit.sh" \
  --name "nightly-security-audit" \
  --description "每日安全审计" \
  --cron "0 3 * * *" \
  --tz "Asia/Shanghai" \
  --session "isolated" \
  --light-context \
  --model "<your-model>" \
  --message "执行此命令，然后将输出总结为简洁的安全报告。用 emoji 状态指示器（🚨/⚠️/✅）列出全部 13 项。以一行汇总标题开始，显示严重/警告/正常计数。命令: bash $OC/workspace/scripts/nightly-security-audit.sh" \
  --announce \
  --channel <your-channel> \
  --to <your-chat-id> \
  --timeout-seconds 300 \
  --thinking off
```

> **时区说明**: 
> - 示例使用 `Asia/Shanghai` (UTC+8)
> - 美国东部时区使用 `America/New_York`
> - 其他时区参考: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones

#### 4.3 验证 Cron 任务

```bash
# 列出所有定时任务
openclaw cron list

# 记录任务 ID
# 应看到: nightly-security-audit
```

#### 4.4 立即测试执行

```bash
# 手动触发一次（替换 <job-id> 为上一步获取的任务 ID）
openclaw cron run --id <job-id>

# 查看执行历史
openclaw cron runs --id <job-id>
```

---

### 步骤 5: 配置 Brain 备份（可选）

如果需要远程备份 OpenClaw 状态，可以配置 Git 同步：

#### 5.1 检查 Git 状态

```bash
cd $OC
git status
# 如果提示 "not a git repository"，继续下一步
```

#### 5.2 初始化 Git 仓库

```bash
cd $OC

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

# Node modules（如果有）
node_modules/
EOF

# 添加并提交
git add .
git commit -m "Initial OpenClaw state backup"
```

#### 5.3 添加远程仓库

```bash
# 添加你的私有 Git 仓库（需提前创建）
git remote add origin <your-private-repo-url>

# 推送到远程
git push -u origin main
```

#### 5.4 配置自动备份

审计脚本默认包含 Git 自动推送逻辑。如果需要独立的备份任务：

```bash
# 创建独立的备份脚本
cat > $OC/workspace/scripts/backup-brain.sh << 'EOF'
#!/bin/bash
cd "${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
git add .
git commit -m "Auto backup $(date +%Y-%m-%d_%H:%M:%S)" || true
git push origin main
EOF

chmod +x $OC/workspace/scripts/backup-brain.sh

# 测试备份
bash $OC/workspace/scripts/backup-brain.sh
```

---

## ✅ 配置完成检查清单

完成所有步骤后，执行以下检查：

```bash
# 1. 核心文件权限
ls -l $OC/openclaw.json $OC/devices/paired.json | grep "^-rw-------"

# 2. 哈希基线存在
test -f $OC/.config-baseline.sha256 && echo "✅ 基线已建立"

# 3. 审计脚本已锁定
lsattr $OC/workspace/scripts/nightly-security-audit.sh | grep -q "i" && echo "✅ 脚本已锁定"

# 4. Cron 任务已注册
openclaw cron list | grep -q "nightly-security-audit" && echo "✅ 定时任务已注册"

# 5. 最近一次审计报告存在
ls -lh $OC/security-reports/report-*.txt | tail -1
```

---

## 📊 日常维护

### 查看审计报告

```bash
# 查看最新报告
ls -t $OC/security-reports/report-*.txt | head -1 | xargs cat

# 查看指定日期报告
cat $OC/security-reports/report-2026-03-28.txt

# 查看最近 7 天的报告
ls -t $OC/security-reports/report-*.txt | head -7
```

### 审计脚本维护

```bash
# 解锁脚本
sudo chattr -i $OC/workspace/scripts/nightly-security-audit.sh

# 编辑脚本
vim $OC/workspace/scripts/nightly-security-audit.sh

# 测试修改
bash $OC/workspace/scripts/nightly-security-audit.sh

# 重新锁定
sudo chattr +i $OC/workspace/scripts/nightly-security-audit.sh
```

### OpenClaw 升级后

```bash
# 1. 升级 OpenClaw
npm i -g openclaw@latest
# 如果使用 nvm，不要用 sudo

# 2. 重启 Gateway
openclaw gateway restart

# 3. 验证
openclaw --version
systemctl --user is-active openclaw-gateway

# 4. 重建配置基线
sha256sum $OC/openclaw.json > $OC/.config-baseline.sha256

# 5. 如果安装了新 Skill，更新 Skill 基线
find $OC/workspace/skills -type f -not -path '*/.git/*' -exec sha256sum {} \; | sort | sha256sum > $OC/.skill-baseline.sha256
```

---

## 🔍 故障排查

### Cron 任务未执行

```bash
# 查看任务执行历史
openclaw cron runs --id <job-id>

# 查看详细日志
openclaw logs gateway

# 检查 Gateway 状态
openclaw gateway status
```

### 审计报告未推送到聊天

可能原因：
1. Telegram/Discord API 临时故障（502/503）
2. chatId 不正确
3. 超时（脚本执行时间 > 300秒）

解决方案：
```bash
# 报告始终保存在本地，可以手动查看
cat $OC/security-reports/report-$(date +%Y-%m-%d).txt

# 调整超时时间
openclaw cron edit --id <job-id> --timeout-seconds 600
```

### 基线验证失败

```bash
# 查看是什么文件变化了
sha256sum $OC/openclaw.json

# 如果确认变化是合法的（如配置更新），重建基线
sha256sum $OC/openclaw.json > $OC/.config-baseline.sha256
```

---

## 📚 相关文档

- [OpenClaw Security Practice Guide v2.8](./OpenClaw-Security-Practice-Guide-v2.8.md) - 完整安全实践指南
- [OpenClaw 极简安全实践指南 v2.8](./OpenClaw极简安全实践指南v2.8.md) - 中文完整版
- [Validation Guide](./Validation-Guide-zh.md) - 验证指南

---

## ⚠️ 重要提醒

1. **定期检查**: 建议每周查看一次审计报告，确保没有遗漏的安全警告
2. **备份验证**: 如果配置了 Git 备份，定期验证远程仓库同步正常
3. **审计脚本**: 审计脚本本身是安全的关键，务必保持 `chattr +i` 锁定状态
4. **误报处理**: 对于确认的误报，添加到 `.security-audit-known-issues.json`，而不是忽略审计输出
5. **访问控制**: 务必保护好 AWS 实例的 SSH 密钥和 OpenClaw 的配对设备

---

## 🆘 获取帮助

遇到问题？
- 提交 Issue: https://github.com/holynull/openclaw-security-practice-guide/issues
- OpenClaw 官方文档: https://docs.openclaw.ai
