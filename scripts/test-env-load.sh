#!/bin/bash
# OpenClaw 环境变量加载测试脚本
# 用于验证 .env 文件是否能被正确加载

export OPENCLAW_STATE_DIR="${OPENCLAW_STATE_DIR:-$HOME/.openclaw3}"

echo "=== OpenClaw 环境变量加载测试 ==="
echo ""
echo "状态目录: $OPENCLAW_STATE_DIR"
echo ""

# 检查 .env 文件是否存在
if [ ! -f "$OPENCLAW_STATE_DIR/.env" ]; then
  echo "❌ 错误: .env 文件不存在"
  echo "   路径: $OPENCLAW_STATE_DIR/.env"
  echo ""
  echo "请先创建 .env 文件并填写必要的环境变量。"
  exit 1
fi

echo "✓ .env 文件存在"
echo ""

# 加载环境变量
if [ -f "$OPENCLAW_STATE_DIR/.env" ]; then
  set -a
  source "$OPENCLAW_STATE_DIR/.env"
  set +a
fi

# 测试环境变量是否加载
echo "=== 环境变量加载结果 ==="
echo ""

# 检查各个必要的环境变量
check_var() {
  local var_name=$1
  local var_value=${!var_name}
  
  if [ -z "$var_value" ]; then
    echo "❌ $var_name: 未设置"
    return 1
  elif [[ "$var_value" == *"your_"*"_here" ]]; then
    echo "⚠️  $var_name: 仍为占位符，需要填写真实值"
    return 2
  else
    # 只显示前10个字符
    echo "✓ $var_name: ${var_value:0:10}..."
    return 0
  fi
}

# 测试模型 API 密钥
echo "【模型 API 密钥】"
check_var "GPTSAPI_KEY"
gptsapi_result=$?
check_var "MAYNOR1024_KEY"
maynor_result=$?
check_var "OPENAI_API_KEY"
openai_result=$?

echo ""
echo "【飞书配置】"
check_var "FEISHU_APP_ID"
feishu_id_result=$?
check_var "FEISHU_APP_SECRET"
feishu_secret_result=$?

echo ""
echo "【其他服务】"
check_var "INFURA_KEY"
check_var "BRAVE_API_KEY"

echo ""
echo "=== 子进程继承测试 ==="
echo ""

# 测试子进程是否能继承环境变量
bash -c '
if [ -n "$GPTSAPI_KEY" ]; then
  echo "✓ 子进程可以访问环境变量"
  echo "  GPTSAPI_KEY: ${GPTSAPI_KEY:0:10}..."
else
  echo "❌ 子进程无法访问环境变量"
fi
'

echo ""
echo "=== 测试总结 ==="
echo ""

# 计算结果
errors=0
warnings=0

[ $gptsapi_result -eq 1 ] && ((errors++))
[ $gptsapi_result -eq 2 ] && ((warnings++))
[ $maynor_result -eq 1 ] && ((errors++))
[ $maynor_result -eq 2 ] && ((warnings++))
[ $openai_result -eq 1 ] && ((errors++))
[ $openai_result -eq 2 ] && ((warnings++))
[ $feishu_id_result -eq 1 ] && ((errors++))
[ $feishu_id_result -eq 2 ] && ((warnings++))
[ $feishu_secret_result -eq 1 ] && ((errors++))
[ $feishu_secret_result -eq 2 ] && ((warnings++))

if [ $errors -gt 0 ]; then
  echo "❌ 发现 $errors 个错误：环境变量未设置"
  echo ""
  echo "建议："
  echo "1. 编辑 .env 文件: vim $OPENCLAW_STATE_DIR/.env"
  echo "2. 或使用管理脚本: ~/openclaw-host.sh env"
  exit 1
elif [ $warnings -gt 0 ]; then
  echo "⚠️  发现 $warnings 个警告：环境变量为占位符"
  echo ""
  echo "请替换占位符为真实的 API 密钥："
  echo "  vim $OPENCLAW_STATE_DIR/.env"
  echo ""
  echo "或从现有实例复制："
  echo "  docker exec openclaw-cli env | grep -E 'GPTSAPI_KEY|MAYNOR1024_KEY|FEISHU'"
  exit 2
else
  echo "✅ 所有环境变量已正确配置"
  echo ""
  echo "环境变量加载机制正常工作！"
  echo "可以通过管理脚本启动 Gateway："
  echo "  ~/openclaw-host.sh start"
  exit 0
fi
