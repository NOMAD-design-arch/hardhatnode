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

print_color $BLUE "🚀 Hardhat 以太坊主网 Fork 项目设置"
print_color $BLUE "================================\n"

# 检查是否在Ubuntu系统上
if [[ ! -f /etc/lsb-release ]] && [[ ! -f /etc/debian_version ]]; then
    print_color $YELLOW "警告: 此脚本主要为Ubuntu系统设计，您的系统可能需要手动安装某些依赖"
fi

# 1. 检查并安装Node.js
check_install_nodejs() {
    print_color $BLUE "1. 检查Node.js安装状态..."
    
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version)
        print_color $GREEN "✓ Node.js 已安装: $NODE_VERSION"
        
        # 检查版本是否 >= 18
        NODE_MAJOR_VERSION=$(echo $NODE_VERSION | cut -d'.' -f1 | sed 's/v//')
        if [ "$NODE_MAJOR_VERSION" -lt 18 ]; then
            print_color $YELLOW "⚠ Node.js版本过低，建议升级到18+版本"
        fi
    else
        print_color $YELLOW "Node.js 未安装，正在安装..."
        
        # 安装Node.js 18
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt-get install -y nodejs
        
        if command -v node &> /dev/null; then
            NODE_VERSION=$(node --version)
            print_color $GREEN "✓ Node.js 安装成功: $NODE_VERSION"
        else
            print_color $RED "❌ Node.js 安装失败"
            exit 1
        fi
    fi
}

# 2. 创建.env文件
setup_env_file() {
    print_color $BLUE "\n2. 设置环境配置文件..."
    
    if [ -f ".env" ]; then
        print_color $YELLOW "⚠ .env文件已存在，跳过创建"
    else
        if [ -f ".env.example" ]; then
            cp .env.example .env
            print_color $GREEN "✓ 已从.env.example创建.env文件"
        else
            # 如果.env.example不存在，创建一个基本的.env文件
            cat > .env << 'EOF'
# 以太坊主网RPC端点 - 请替换为您的Infura或Alchemy API密钥
MAINNET_RPC_URL=https://mainnet.infura.io/v3/YOUR_INFURA_API_KEY
# 或者使用Alchemy
# MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_ALCHEMY_API_KEY

# Fork网络的端口
FORK_PORT=8545

# Fork的区块号（可选，留空则使用最新区块）
FORK_BLOCK_NUMBER=

# 本地网络配置
NETWORK_ID=1337
GAS_LIMIT=30000000
GAS_PRICE=8000000000

# 预设账户私钥（用于测试，请不要在生产环境使用）
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# Hardhat节点选项
ACCOUNTS_COUNT=20
ACCOUNTS_BALANCE=10000
EOF
            print_color $GREEN "✓ 已创建.env文件"
        fi
        
        print_color $YELLOW "🔧 请编辑.env文件，设置您的MAINNET_RPC_URL："
        print_color $YELLOW "   nano .env"
    fi
}

# 3. 安装项目依赖
install_dependencies() {
    print_color $BLUE "\n3. 安装项目依赖..."
    
    if [ -f "package.json" ]; then
        print_color $BLUE "正在安装npm依赖..."
        npm install
        
        if [ $? -eq 0 ]; then
            print_color $GREEN "✓ 依赖安装成功"
        else
            print_color $RED "❌ 依赖安装失败"
            exit 1
        fi
    else
        print_color $RED "❌ 未找到package.json文件"
        exit 1
    fi
}

# 4. 设置脚本权限
setup_permissions() {
    print_color $BLUE "\n4. 设置脚本执行权限..."
    
    if [ -f "fork-control.sh" ]; then
        chmod +x fork-control.sh
        print_color $GREEN "✓ fork-control.sh 权限设置完成"
    else
        print_color $YELLOW "⚠ 未找到fork-control.sh文件"
    fi
    
    chmod +x setup.sh
    print_color $GREEN "✓ setup.sh 权限设置完成"
}

# 5. 验证安装
verify_installation() {
    print_color $BLUE "\n5. 验证安装..."
    
    # 检查Hardhat
    if npx hardhat --version > /dev/null 2>&1; then
        HARDHAT_VERSION=$(npx hardhat --version)
        print_color $GREEN "✓ Hardhat: $HARDHAT_VERSION"
    else
        print_color $RED "❌ Hardhat验证失败"
        return 1
    fi
    
    # 检查配置文件
    if [ -f "hardhat.config.js" ]; then
        print_color $GREEN "✓ hardhat.config.js 存在"
    else
        print_color $RED "❌ hardhat.config.js 不存在"
        return 1
    fi
    
    if [ -f ".env" ]; then
        print_color $GREEN "✓ .env 文件存在"
    else
        print_color $RED "❌ .env 文件不存在"
        return 1
    fi
    
    return 0
}

# 显示使用说明
show_usage() {
    print_color $BLUE "\n🎉 安装完成！\n"
    
    print_color $GREEN "下一步操作："
    print_color $YELLOW "1. 编辑.env文件，设置您的以太坊RPC URL："
    echo "   nano .env"
    echo ""
    print_color $YELLOW "2. 启动Hardhat fork节点："
    echo "   ./fork-control.sh start"
    echo ""
    print_color $YELLOW "3. 查看节点状态："
    echo "   ./fork-control.sh status"
    echo ""
    print_color $YELLOW "4. 运行测试脚本："
    echo "   npx hardhat run test-fork.js --network localhost"
    echo ""
    
    print_color $BLUE "常用命令："
    echo "  ./fork-control.sh start    # 启动节点"
    echo "  ./fork-control.sh stop     # 停止节点"
    echo "  ./fork-control.sh status   # 查看状态"
    echo "  ./fork-control.sh logs     # 查看日志"
    echo "  ./fork-control.sh help     # 显示帮助"
    echo ""
    
    print_color $GREEN "如需帮助请查看README.md文件"
}

# 主执行流程
main() {
    # 更新包管理器
    print_color $BLUE "更新包管理器..."
    sudo apt-get update -qq
    
    # 安装基本工具
    sudo apt-get install -y curl wget gnupg2 software-properties-common
    
    # 执行安装步骤
    check_install_nodejs
    setup_env_file
    install_dependencies
    setup_permissions
    
    if verify_installation; then
        show_usage
    else
        print_color $RED "\n❌ 验证失败，请检查安装过程中的错误信息"
        exit 1
    fi
}

# 运行主函数
main