#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印彩色输出
print_color() {
    echo -e "${1}${2}${NC}"
}

print_color $BLUE "🔧 Hardhat Fork 故障排除工具"
print_color $BLUE "==========================\n"

# 检查.env文件
check_env_file() {
    print_color $BLUE "1. 检查环境配置..."
    
    if [ ! -f ".env" ]; then
        print_color $RED "❌ .env文件不存在"
        print_color $YELLOW "解决方案: cp .env.example .env 然后编辑.env文件"
        return 1
    fi
    
    print_color $GREEN "✅ .env文件存在"
    
    # 检查关键配置
    source .env 2>/dev/null
    
    if [ -z "$MAINNET_RPC_URL" ] || [ "$MAINNET_RPC_URL" = "https://mainnet.infura.io/v3/YOUR_INFURA_API_KEY" ]; then
        print_color $RED "❌ MAINNET_RPC_URL未正确配置"
        print_color $YELLOW "请在.env文件中设置有效的RPC URL"
        return 1
    fi
    
    print_color $GREEN "✅ MAINNET_RPC_URL已配置"
    
    # 显示当前配置
    echo "当前配置:"
    echo "  FORK_HOST: ${FORK_HOST:-127.0.0.1}"
    echo "  FORK_PORT: ${FORK_PORT:-8545}"
    echo "  MAINNET_RPC_URL: ${MAINNET_RPC_URL:0:50}..."
    echo ""
}

# 检查依赖
check_dependencies() {
    print_color $BLUE "2. 检查依赖..."
    
    # Node.js
    if ! command -v node &> /dev/null; then
        print_color $RED "❌ Node.js未安装"
        return 1
    fi
    print_color $GREEN "✅ Node.js: $(node --version)"
    
    # npm
    if ! command -v npm &> /dev/null; then
        print_color $RED "❌ npm未安装"
        return 1
    fi
    print_color $GREEN "✅ npm: $(npm --version)"
    
    # node_modules
    if [ ! -d "node_modules" ]; then
        print_color $RED "❌ 项目依赖未安装"
        print_color $YELLOW "运行: npm install"
        return 1
    fi
    print_color $GREEN "✅ 项目依赖已安装"
    
    # Hardhat
    if ! npx hardhat --version &> /dev/null; then
        print_color $RED "❌ Hardhat不可用"
        return 1
    fi
    print_color $GREEN "✅ Hardhat: $(npx hardhat --version)"
    echo ""
}

# 检查节点状态
check_node_status() {
    print_color $BLUE "3. 检查节点状态..."
    
    PID_FILE=".hardhat_node.pid"
    
    if [ ! -f "$PID_FILE" ]; then
        print_color $YELLOW "⚠ 节点未运行（无PID文件）"
        return 1
    fi
    
    PID=$(cat $PID_FILE)
    if ! ps -p $PID > /dev/null 2>&1; then
        print_color $RED "❌ 节点进程不存在（PID: $PID）"
        rm -f $PID_FILE
        return 1
    fi
    
    print_color $GREEN "✅ 节点正在运行（PID: $PID）"
    
    # 检查端口
    source .env 2>/dev/null
    PORT=${FORK_PORT:-8545}
    
    if netstat -tln 2>/dev/null | grep ":$PORT " > /dev/null; then
        print_color $GREEN "✅ 端口 $PORT 正在监听"
    else
        print_color $RED "❌ 端口 $PORT 未在监听"
        return 1
    fi
    echo ""
}

# 检查网络连接
check_network_connection() {
    print_color $BLUE "4. 检查网络连接..."
    
    source .env 2>/dev/null
    PORT=${FORK_PORT:-8545}
    HOST=${FORK_HOST:-127.0.0.1}
    
    # 测试本地连接
    if curl -s -X POST -H "Content-Type: application/json" \
       --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
       http://127.0.0.1:$PORT > /dev/null; then
        print_color $GREEN "✅ 本地连接正常"
    else
        print_color $RED "❌ 本地连接失败"
        return 1
    fi
    
    # 如果配置了外部访问，测试外部连接
    if [ "$HOST" = "0.0.0.0" ]; then
        print_color $BLUE "检查外部访问配置..."
        
        # 获取本机IP
        LOCAL_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "unknown")
        
        if [ "$LOCAL_IP" != "unknown" ]; then
            print_color $GREEN "✅ 外部访问已配置"
            echo "  本机IP: $LOCAL_IP"
            echo "  外部RPC URL: http://$LOCAL_IP:$PORT"
        else
            print_color $YELLOW "⚠ 无法获取本机IP地址"
        fi
    else
        print_color $YELLOW "ℹ 当前仅允许本地访问 (FORK_HOST=$HOST)"
    fi
    echo ""
}

# 测试RPC连接
test_rpc_connection() {
    print_color $BLUE "5. 测试RPC功能..."
    
    source .env 2>/dev/null
    PORT=${FORK_PORT:-8545}
    
    # 测试基本RPC调用
    RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" \
               --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
               http://127.0.0.1:$PORT)
    
    if echo "$RESPONSE" | grep -q "result"; then
        BLOCK_HEX=$(echo "$RESPONSE" | grep -o '"result":"[^"]*"' | cut -d'"' -f4)
        BLOCK_DEC=$((BLOCK_HEX))
        print_color $GREEN "✅ RPC调用成功"
        echo "  当前区块号: $BLOCK_DEC"
    else
        print_color $RED "❌ RPC调用失败"
        echo "响应: $RESPONSE"
        return 1
    fi
    echo ""
}

# 运行连接测试
run_connection_test() {
    print_color $BLUE "6. 运行连接测试脚本..."
    
    if [ -f "check-connection.js" ]; then
        if npx hardhat run check-connection.js --network localhost 2>/dev/null; then
            print_color $GREEN "✅ 连接测试通过"
        else
            print_color $RED "❌ 连接测试失败"
            print_color $YELLOW "尝试运行: npx hardhat run check-connection.js --network localhost"
            return 1
        fi
    else
        print_color $YELLOW "⚠ 连接测试脚本不存在"
    fi
    echo ""
}

# 显示Remix连接指南
show_remix_guide() {
    print_color $BLUE "7. Remix连接指南..."
    
    source .env 2>/dev/null
    PORT=${FORK_PORT:-8545}
    HOST=${FORK_HOST:-127.0.0.1}
    
    if [ "$HOST" = "0.0.0.0" ]; then
        LOCAL_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "YOUR_IP")
        RPC_URL="http://$LOCAL_IP:$PORT"
    else
        RPC_URL="http://127.0.0.1:$PORT"
    fi
    
    print_color $GREEN "Remix IDE 连接步骤:"
    echo "1. 打开 https://remix.ethereum.org"
    echo "2. 进入 Deploy & Run Transactions 页面"
    echo "3. Environment 选择 'External Http Provider'"
    echo "4. 输入 RPC URL: $RPC_URL"
    echo "5. 确认连接"
    echo ""
    
    print_color $GREEN "MetaMask 网络配置:"
    echo "- 网络名称: Hardhat Fork"
    echo "- RPC URL: $RPC_URL"
    echo "- 链ID: 1337"
    echo "- 货币符号: ETH"
    echo ""
}

# 提供解决方案建议
suggest_solutions() {
    print_color $BLUE "8. 解决方案建议..."
    
    print_color $YELLOW "如果遇到问题，请尝试以下解决方案:"
    echo ""
    echo "🔧 基本问题:"
    echo "  1. 重启节点: ./fork-control.sh restart"
    echo "  2. 检查日志: ./fork-control.sh logs"
    echo "  3. 重新安装依赖: rm -rf node_modules && npm install"
    echo ""
    echo "🌐 连接问题:"
    echo "  1. 确保防火墙允许端口访问"
    echo "  2. 检查.env文件中的FORK_HOST配置"
    echo "  3. 使用正确的IP地址和端口"
    echo ""
    echo "🔑 RPC问题:"
    echo "  1. 验证MAINNET_RPC_URL是否有效"
    echo "  2. 检查API密钥限制和配额"
    echo "  3. 尝试不同的RPC提供商"
    echo ""
    echo "📱 Remix问题:"
    echo "  1. 确保使用http://而不是https://"
    echo "  2. 检查浏览器控制台错误"
    echo "  3. 尝试刷新Remix页面"
    echo ""
}

# 主执行函数
main() {
    local exit_code=0
    
    check_env_file || exit_code=1
    check_dependencies || exit_code=1
    check_node_status || exit_code=1
    
    if [ $exit_code -eq 0 ]; then
        check_network_connection || exit_code=1
        test_rpc_connection || exit_code=1
        run_connection_test || exit_code=1
    fi
    
    show_remix_guide
    suggest_solutions
    
    if [ $exit_code -eq 0 ]; then
        print_color $GREEN "\n🎉 所有检查通过！您的Hardhat fork节点应该可以正常使用。"
    else
        print_color $RED "\n❌ 发现问题，请根据上述建议进行修复。"
    fi
    
    return $exit_code
}

# 运行主函数
main 