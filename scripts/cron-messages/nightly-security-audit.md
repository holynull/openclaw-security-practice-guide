# 宿主机每日安全审计任务

> **部署位置**: `~/.openclaw3/workspace/team/cron_messages/nightly-security-audit.md`  
> **接收者**: 报告将发送到飞书用户 `ou_0fa58dc0ea9bebec570346e829677da7`

## 执行步骤

### 1. 执行安全审计脚本

运行以下命令生成审计报告：

```bash
bash $HOME/.openclaw3/workspace/scripts/nightly-security-audit.sh
```

### 2. 读取审计报告

使用 read 工具读取今日报告：

```
read({
  path: "$HOME/.openclaw3/security-reports/report-YYYY-MM-DD.txt"
})
```

将 YYYY-MM-DD 替换为当前日期（如 2026-04-08）。

### 3. 生成飞书格式报告

根据审计报告内容，生成飞书 Markdown 格式的报告：

**报告格式要求**：
- ✅ 使用 **粗体** 和 [链接](url)
- ✅ 使用 emoji 状态指示器（🚨/⚠️/✅）
- ❌ 不使用 ## 标题（lark_md 不支持）
- ❌ 不使用列表语法（用粗体+换行代替）

**报告结构**：

```markdown
🔒 **OpenClaw 宿主机安全审计报告**

日期：{当前日期}
实例：~/.openclaw3

━━━━━━━━━━━━━━━━━━━━

📊 **安全状态总览**

🚨 严重问题：{count}
⚠️ 警告：{count}
✅ 正常：{count}

━━━━━━━━━━━━━━━━━━━━

📋 **详细检查结果**

**{status} 检查项 1：核心配置文件权限**
状态：{描述}
{如有问题，说明详情}

**{status} 检查项 2：敏感文件权限**
状态：{描述}

**{status} 检查项 3：审计脚本完整性**
状态：{描述}

**{status} 检查项 4：审计脚本不可篡改性**
状态：{描述}

**{status} 检查项 5：配置文件基线完整性**
状态：{描述}

**{status} 检查项 6：异常网络连接**
状态：{描述}

**{status} 检查项 7：未授权进程**
状态：{描述}

**{status} 检查项 8：SSH 配置安全**
状态：{描述}

**{status} 检查项 9：系统更新状态**
状态：{描述}

**{status} 检查项 10：磁盘空间**
状态：{描述}

**{status} 检查项 11：日志文件完整性**
状态：{描述}

**{status} 检查项 12：备份状态**
状态：{描述}

**{status} 检查项 13：环境变量安全**
状态：{描述}

━━━━━━━━━━━━━━━━━━━━

💡 **建议措施**

{根据发现的问题，给出具体的修复建议，如：}

**立即处理：**
- 修复权限问题：chmod 600 file.json
- 更新配置基线：sha256sum file.json > file.json.sha256

**近期关注：**
- 清理过期日志文件
- 验证备份可用性

━━━━━━━━━━━━━━━━━━━━

⏰ 生成时间：{时间戳}
```

### 4. 发送报告到飞书

调用 send_feishu_file_content 工具发送报告：

```
send_feishu_file_content({
  filePath: "{步骤3生成的完整 Markdown 报告文本}",
  chatId: "ou_0fa58dc0ea9bebec570346e829677da7",
  title: "🔒 OpenClaw 宿主机安全审计报告",
  useMarkdown: true
})
```

**参数说明**：
- `filePath`: 完整的 Markdown 报告内容（字符串）
- `chatId`: 飞书用户 ID `ou_0fa58dc0ea9bebec570346e829677da7`（固定接收者）
- `title`: 消息卡片标题
- `useMarkdown: true`: 启用 lark_md 渲染

## ⚠️ 重要提示

- **必须完整执行所有 4 个步骤**
- **步骤 3 生成的报告必须包含所有 13 项检查结果**
- **不要省略任何检查项，不要使用 "..." 表示省略**
- **必须设置 `useMarkdown: true` 以正确渲染格式**
- **在发送之前不要输出报告内容（避免重复）**

## 📝 配置说明

### 接收者设置

报告已配置为固定发送给飞书用户：
- **User ID**: `ou_0fa58dc0ea9bebec570346e829677da7`
- **发送方式**: 使用 `send_feishu_file_content` 工具
- **消息格式**: 飞书 lark_md 渲染的 Markdown 卡片

### 修改接收者

如需更改接收者，修改步骤 4 中的 `chatId` 参数：

```bash
# 编辑任务模板
vim ~/.openclaw3/workspace/team/cron_messages/nightly-security-audit.md

# 修改 chatId 为新的用户 ID 或群组 ID
# 用户 ID: ou_xxxxxxxxxxxxxxxxxx
# 群组 ID: oc_xxxxxxxxxxxxxxxxxx
```

### 获取飞书 ID

```bash
# 查看已配对设备信息
openclaw device list

# 从输出中找到 chatId
# 用户格式: ou_xxxxxxxxxxxxxxxxxx
# 群组格式: oc_xxxxxxxxxxxxxxxxxx
```

## 🔗 相关文档

- [宿主机部署指南](../../docs/Host-Instance-Deployment-Guide-zh.md) - 完整部署流程
- [安全实践指南 v2.8](../../docs/OpenClaw-Security-Practice-Guide-v2.8.md) - 审计项说明
- [feishu-messaging 插件](../../extensions/feishu-messaging/README.md) - 插件使用文档
