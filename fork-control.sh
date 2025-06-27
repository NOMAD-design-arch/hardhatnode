#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置文件
ENV_FILE=".env"
PID_FILE=".hardhat_node.pid"
LOG_FILE="hardhat_node.log"

# 打印彩色输出
print_color() {
    echo -e "${1}${2}${NC}"
}

# 检查环境配置
check_env() {
    if [ ! -f "$ENV_FILE" ]; then
        print_color $RED "错误: 未找到 .env 文件"
        print_color $YELLOW "请确保 .env 文件存在并包含必要的配置"
        exit 1
    fi
    
    source $ENV_FILE
    
    if [ -z "$MAINNET_RPC_URL" ] || [ "$MAINNET_RPC_URL" = "https://mainnet.infura.io/v3/YOUR_INFURA_API_KEY" ]; then
        print_color $RED "错误: 请在 .env 文件中设置有效的 MAINNET_RPC_URL"
        print_color $YELLOW "请替换 YOUR_INFURA_API_KEY 为您的实际API密钥"
        exit 1
    fi
}

# 检查系统依赖
check_dependencies() {
    print_color $BLUE "检查系统依赖..."
    
    # 检查 Node.js
    if ! command -v node &> /dev/null; then
        print_color $RED "错误: 未安装 Node.js"
        print_color $YELLOW "请安装 Node.js (推荐版本 >= 18):"
        echo "curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -"
        echo "sudo apt-get install -y nodejs"
        exit 1
    else
        NODE_VERSION=$(node --version)
        print_color $GREEN "✓ Node.js 已安装: $NODE_VERSION"
    fi
    
    # 检查 npm
    if ! command -v npm &> /dev/null; then
        print_color $RED "错误: 未安装 npm"
        exit 1
    else
        NPM_VERSION=$(npm --version)
        print_color $GREEN "✓ npm 已安装: $NPM_VERSION"
    fi
    
    # 检查项目依赖
    if [ ! -d "node_modules" ]; then
        print_color $YELLOW "正在安装项目依赖..."
        npm install
        if [ $? -ne 0 ]; then
            print_color $RED "错误: 依赖安装失败"
            exit 1
        fi
    fi
    
    # 检查 Hardhat
    if ! npx hardhat --version &> /dev/null; then
        print_color $RED "错误: Hardhat 未正确安装"
        exit 1
    else
        HARDHAT_VERSION=$(npx hardhat --version)
        print_color $GREEN "✓ Hardhat 已安装: $HARDHAT_VERSION"
    fi
}

# 启动节点
start_node() {
    check_env
    check_dependencies
    
    if [ -f "$PID_FILE" ]; then
        PID=$(cat $PID_FILE)
        if ps -p $PID > /dev/null 2>&1; then
            print_color $YELLOW "节点已在运行 (PID: $PID)"
            return
        else
            rm -f $PID_FILE
        fi
    fi
    
    print_color $BLUE "启动 Hardhat fork 节点..."
    source $ENV_FILE
    
    # 构建启动命令
    FORK_CMD="npx hardhat node"
    if [ ! -z "$MAINNET_RPC_URL" ]; then
        FORK_CMD="$FORK_CMD --fork $MAINNET_RPC_URL"
    fi
    if [ ! -z "$FORK_BLOCK_NUMBER" ]; then
        FORK_CMD="$FORK_CMD --fork-block-number $FORK_BLOCK_NUMBER"
    fi
    if [ ! -z "$FORK_PORT" ]; then
        FORK_CMD="$FORK_CMD --port $FORK_PORT"
    fi
    if [ ! -z "$FORK_HOST" ]; then
        FORK_CMD="$FORK_CMD --hostname $FORK_HOST"
    fi
    
    # 后台启动节点
    nohup $FORK_CMD > $LOG_FILE 2>&1 &
    NODE_PID=$!
    echo $NODE_PID > $PID_FILE
    
    # 等待节点启动
    sleep 3
    
    if ps -p $NODE_PID > /dev/null 2>&1; then
        print_color $GREEN "✓ 节点启动成功!"
        print_color $BLUE "PID: $NODE_PID"
        print_color $BLUE "端口: ${FORK_PORT:-8545}"
        print_color $BLUE "主机: ${FORK_HOST:-127.0.0.1}"
        print_color $BLUE "日志文件: $LOG_FILE"
        print_color $BLUE "RPC URL: http://${FORK_HOST:-127.0.0.1}:${FORK_PORT:-8545}"
    else
        print_color $RED "错误: 节点启动失败"
        print_color $YELLOW "请查看日志文件: $LOG_FILE"
        rm -f $PID_FILE
        exit 1
    fi
}

# 停止节点
stop_node() {
    if [ ! -f "$PID_FILE" ]; then
        print_color $YELLOW "节点未在运行"
        return
    fi
    
    PID=$(cat $PID_FILE)
    if ps -p $PID > /dev/null 2>&1; then
        print_color $BLUE "停止节点 (PID: $PID)..."
        kill $PID
        
        # 等待进程结束
        for i in {1..10}; do
            if ! ps -p $PID > /dev/null 2>&1; then
                break
            fi
            sleep 1
        done
        
        # 强制杀死进程
        if ps -p $PID > /dev/null 2>&1; then
            kill -9 $PID
        fi
        
        rm -f $PID_FILE
        print_color $GREEN "✓ 节点已停止"
    else
        print_color $YELLOW "节点进程不存在，清理PID文件"
        rm -f $PID_FILE
    fi
}

# 查看状态
status_node() {
    print_color $BLUE "=== Hardhat Fork 节点状态 ==="
    
    if [ -f "$PID_FILE" ]; then
        PID=$(cat $PID_FILE)
        if ps -p $PID > /dev/null 2>&1; then
            print_color $GREEN "✓ 节点正在运行"
            print_color $BLUE "PID: $PID"
            
            # 获取进程信息
            PROCESS_INFO=$(ps -p $PID -o pid,ppid,cmd --no-headers)
            print_color $BLUE "进程信息: $PROCESS_INFO"
            
            # 检查端口
            source $ENV_FILE 2>/dev/null
            PORT=${FORK_PORT:-8545}
            if netstat -tln 2>/dev/null | grep ":$PORT " > /dev/null; then
                print_color $GREEN "✓ 端口 $PORT 正在监听"
                print_color $BLUE "RPC URL: http://${FORK_HOST:-127.0.0.1}:$PORT"
            else
                print_color $YELLOW "⚠ 端口 $PORT 未在监听"
            fi
        else
            print_color $RED "✗ 节点进程不存在 (PID文件过期)"
            rm -f $PID_FILE
        fi
    else
        print_color $YELLOW "✗ 节点未运行"
    fi
    
    # 显示最近的日志
    if [ -f "$LOG_FILE" ]; then
        print_color $BLUE "\n=== 最近日志 (最后10行) ==="
        tail -n 10 $LOG_FILE
    fi
}

# 查看日志
show_logs() {
    if [ -f "$LOG_FILE" ]; then
        print_color $BLUE "=== Hardhat 节点日志 ==="
        tail -f $LOG_FILE
    else
        print_color $YELLOW "日志文件不存在"
    fi
}

# 显示帮助
show_help() {
    echo "用法: $0 {start|stop|status|logs|restart|help}"
    echo ""
    echo "命令:"
    echo "  start   - 启动 Hardhat fork 节点"
    echo "  stop    - 停止节点"
    echo "  status  - 查看节点状态"
    echo "  logs    - 实时查看日志 (Ctrl+C 退出)"
    echo "  restart - 重启节点"
    echo "  help    - 显示此帮助信息"
    echo ""
    echo "配置文件: .env"
    echo "日志文件: $LOG_FILE"
    echo "PID文件: $PID_FILE"
}

# 重启节点
restart_node() {
    print_color $BLUE "重启节点..."
    stop_node
    sleep 2
    start_node
}

# 主逻辑
case "${1}" in
    start)
        start_node
        ;;
    stop)
        stop_node
        ;;
    status)
        status_node
        ;;
    logs)
        show_logs
        ;;
    restart)
        restart_node
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_color $RED "错误: 未知命令 '$1'"
        show_help
        exit 1
        ;;
esac 