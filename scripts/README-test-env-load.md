# 环境变量加载测试脚本

## 📄 脚本说明

`test-env-load.sh` - 用于验证 OpenClaw 宿主机实例的环境变量配置是否正确。

## 🎯 功能

1. ✅ 检查 `.env` 文件是否存在
2. ✅ 验证必要的环境变量是否已设置
3. ✅ 检测占位符是否已替换为真实值
4. ✅ 测试子进程是否能继承环境变量
5. ✅ 提供详细的错误报告和修复建议

## 📦 使用方法

### 在本地测试（开发环境）

```bash
# 克隆仓库
cd openclaw-security-practice-guide

# 运行测试脚本（指定状态目录）
OPENCLAW_STATE_DIR=~/.openclaw3 bash scripts/test-env-load.sh
```

### 在服务器上测试（生产环境）

#### 方式 1: 直接从 GitHub 运行

```bash
# 下载并运行
curl -sSL https://raw.githubusercontent.com/holynull/openclaw-security-practice-guide/main/scripts/test-env-load.sh | bash
```

#### 方式 2: 复制到服务器

```bash
# 从本地复制
scp scripts/test-env-load.sh user@server:~/.openclaw3/

# 在服务器上运行
ssh user@server "bash ~/.openclaw3/test-env-load.sh"
```

#### 方式 3: 在服务器上直接创建

```bash
# SSH 到服务器
ssh user@server

# 下载脚本
cd ~/.openclaw3
curl -O https://raw.githubusercontent.com/holynull/openclaw-security-practice-guide/main/scripts/test-env-load.sh
chmod +x test-env-load.sh

# 运行测试
./test-env-load.sh
```

## 📊 输出示例

### 成功示例

```
=== OpenClaw 环境变量加载测试 ===

状态目录: /home/ec2-user/.openclaw3

✓ .env 文件存在

=== 环境变量加载结果 ===

【模型 API 密钥】
✓ GPTSAPI_KEY: sk-Uxwb74d...
✓ MAYNOR1024_KEY: sk-ZVCL4dM...
✓ OPENAI_API_KEY: sk-proj-SO...

【飞书配置】
✓ FEISHU_APP_ID: cli_a93271...
✓ FEISHU_APP_SECRET: AaPSs1bn...

【其他服务】
⚠️  INFURA_KEY: 仍为占位符，需要填写真实值
⚠️  BRAVE_API_KEY: 仍为占位符，需要填写真实值

=== 子进程继承测试 ===

✓ 子进程可以访问环境变量
  GPTSAPI_KEY: sk-Uxwb74d...

=== 测试总结 ===

✅ 所有环境变量已正确配置

环境变量加载机制正常工作！
可以通过管理脚本启动 Gateway：
  ~/openclaw-host.sh start
```

### 错误示例

```
=== OpenClaw 环境变量加载测试 ===

状态目录: /home/ec2-user/.openclaw3

❌ 错误: .env 文件不存在
   路径: /home/ec2-user/.openclaw3/.env

请先创建 .env 文件并填写必要的环境变量。
```

### 警告示例

```
=== 测试总结 ===

⚠️  发现 3 个警告：环境变量为占位符

请替换占位符为真实的 API 密钥：
  vim /home/ec2-user/.openclaw3/.env

或从现有实例复制：
  docker exec openclaw-cli env | grep -E 'GPTSAPI_KEY|MAYNOR1024_KEY|FEISHU'
```

## 🔍 退出码

- `0` - 所有配置正确
- `1` - 发现错误（环境变量未设置）
- `2` - 发现警告（环境变量为占位符）

## 📋 检查的环境变量

### 必需变量（模型 API）
- `GPTSAPI_KEY`
- `MAYNOR1024_KEY`
- `OPENAI_API_KEY`

### 必需变量（飞书）
- `FEISHU_APP_ID`
- `FEISHU_APP_SECRET`

### 可选变量
- `INFURA_KEY`
- `BRAVE_API_KEY`

## 🛠️ 故障排查

### .env 文件不存在

```bash
# 创建 .env 文件
cat > ~/.openclaw3/.env << 'EOF'
GPTSAPI_KEY=your_gptsapi_key_here
MAYNOR1024_KEY=your_maynor1024_key_here
OPENAI_API_KEY=your_openai_key_here
FEISHU_APP_ID=your_feishu_app_id
FEISHU_APP_SECRET=your_feishu_app_secret
INFURA_KEY=your_infura_key_here
BRAVE_API_KEY=your_brave_api_key_here
EOF

chmod 600 ~/.openclaw3/.env
```

### 环境变量为占位符

```bash
# 编辑 .env 文件
vim ~/.openclaw3/.env

# 或使用管理脚本
~/openclaw-host.sh env

# 替换 "your_*_here" 为真实的 API 密钥
```

### 从现有实例复制

```bash
# 查看 Docker 实例的环境变量
docker exec openclaw-cli env | grep -E "GPTSAPI_KEY|MAYNOR1024_KEY|FEISHU"

# 或从 docker-compose 目录查看
cat ~/github.com/holynull/openclaw/.env

# 然后复制到宿主机的 .env 文件
vim ~/.openclaw3/.env
```

## 🚀 集成到部署流程

在部署指南的适当位置添加：

```bash
# 第一阶段结束后，验证环境变量配置
bash ~/.openclaw3/test-env-load.sh

# 如果通过，继续第二阶段（安全加固）
# 如果失败，根据提示修复后重新测试
```

## 📝 注意事项

1. **安全性**：脚本只显示环境变量的前 10 个字符，不会泄露完整密钥
2. **权限**：确保 `.env` 文件权限为 600（`chmod 600 ~/.openclaw3/.env`）
3. **时机**：建议在启动 Gateway 前运行此脚本验证配置
4. **自动化**：可以集成到 CI/CD 流程中作为健康检查

## 🔗 相关文档

- [宿主机部署指南](../docs/Host-Instance-Deployment-Guide-zh.md)
- [配置指南](~/.openclaw3/CONFIG_GUIDE.md)（服务器上）
- [管理脚本](~/openclaw-host.sh)（服务器上）

---

**版本**: 1.0.0  
**更新日期**: 2026-04-08  
**维护者**: holynull
