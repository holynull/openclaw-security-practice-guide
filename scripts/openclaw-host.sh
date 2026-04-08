#!/bin/bash
# OpenClaw Host Instance Manager
# State Directory: ~/.openclaw3
# Gateway Port: 38789
# 
# 用途：管理宿主机 OpenClaw 实例的启动、停止和配置
# 功能：自动加载 .env 环境变量，提供便捷的管理命令
#
# 安装：
#   cp openclaw-host.sh ~/openclaw-host.sh
#   chmod +x ~/openclaw-host.sh
#
# 使用：
#   ~/openclaw-host.sh start
#   ~/openclaw-host.sh status
#   ~/openclaw-host.sh env

export OPENCLAW_STATE_DIR="$HOME/.openclaw3"

# 加载环境变量
if [ -f "$OPENCLAW_STATE_DIR/.env" ]; then
  set -a
  source "$OPENCLAW_STATE_DIR/.env"
  set +a
fi

case "$1" in
  start)
    echo "Starting OpenClaw Host Gateway (port 38789)..."
    openclaw gateway start
    ;;
  stop)
    echo "Stopping OpenClaw Host Gateway..."
    openclaw gateway stop
    ;;
  restart)
    echo "Restarting OpenClaw Host Gateway..."
    openclaw gateway restart
    ;;
  status)
    echo "=== OpenClaw Host Instance Status ==="
    echo "State Dir: $OPENCLAW_STATE_DIR"
    echo "Gateway Port: 38789"
    echo ""
    openclaw gateway status
    echo ""
    echo "=== All OpenClaw Processes ==="
    ps aux | grep openclaw | grep -v grep
    echo ""
    echo "=== Port Usage ==="
    sudo ss -tlnp | grep -E '(18789|28789|38789)'
    ;;
  pair)
    echo "Pairing device for host instance..."
    openclaw device pair
    ;;
  env)
    echo "Editing environment variables..."
    vim "$OPENCLAW_STATE_DIR/.env"
    echo ""
    echo "Remember to restart gateway after changing environment variables:"
    echo "  ~/openclaw-host.sh restart"
    ;;
  cli)
    shift
    export OPENCLAW_BYPASS_PAIR=true
    openclaw "$@"
    ;;
  *)
    echo "OpenClaw Host Instance Manager"
    echo "State: $OPENCLAW_STATE_DIR"
    echo "Ports: 38789 (gateway)"
    echo ""
    echo "Usage: $0 {start|stop|restart|status|pair|env|cli [命令]}"
    echo ""
    echo "Commands:"
    echo "  start         - 启动 gateway"
    echo "  stop          - 停止 gateway"
    echo "  restart       - 重启 gateway"
    echo "  status        - 查看状态"
    echo "  pair          - 配对设备"
    echo "  env           - 编辑环境变量"
    echo "  cli <cmd>     - 执行 openclaw 命令"
    echo ""
    echo "Examples:"
    echo "  $0 start"
    echo "  $0 status"
    echo "  $0 env"
    echo "  $0 cli device list"
    exit 1
    ;;
esac
