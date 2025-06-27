# Hardhat 以太坊主网 Fork 项目

这个项目提供了一个完整的解决方案，用于在Ubuntu系统上使用Hardhat fork以太坊主网的最新状态。

## 功能特性

- ✅ 自动检测Node.js和Hardhat安装状态
- 🚀 一键启动/停止fork节点
- 📊 实时状态监控
- 📝 详细日志记录
- 🔧 灵活的配置选项

## 前置要求

- Ubuntu系统
- Node.js >= 18
- npm 包管理器
- 有效的以太坊RPC端点（Infura或Alchemy）

## 快速开始

### 1. 配置环境变量

```bash
# 复制环境变量模板
cp .env.example .env

# 编辑配置文件
nano .env
```

**重要：** 请在`.env`文件中设置有效的`MAINNET_RPC_URL`，将`YOUR_INFURA_API_KEY`替换为您的实际API密钥。

### 2. 给脚本执行权限

```bash
chmod +x fork-control.sh
```

### 3. 使用控制脚本

```bash
# 启动节点
./fork-control.sh start

# 查看状态
./fork-control.sh status

# 停止节点
./fork-control.sh stop

# 查看实时日志
./fork-control.sh logs

# 重启节点
./fork-control.sh restart

# 显示帮助
./fork-control.sh help
```

## 脚本命令详解

| 命令 | 描述 |
|------|------|
| `start` | 启动Hardhat fork节点，自动检查依赖 |
| `stop` | 优雅停止运行中的节点 |
| `status` | 显示节点运行状态和最近日志 |
| `logs` | 实时查看节点日志（Ctrl+C退出） |
| `restart` | 重启节点（先停止再启动） |
| `help` | 显示帮助信息 |

## 配置说明

### .env 文件配置项

```bash
# 以太坊主网RPC端点
MAINNET_RPC_URL=https://mainnet.infura.io/v3/YOUR_API_KEY

# fork节点监听端口
FORK_PORT=8545

# 指定fork的区块号（可选）
FORK_BLOCK_NUMBER=

# 网络ID
NETWORK_ID=1337

# Gas配置
GAS_LIMIT=30000000
GAS_PRICE=8000000000

# 测试账户配置
ACCOUNTS_COUNT=20
ACCOUNTS_BALANCE=10000
```

### Hardhat配置

项目使用`hardhat.config.js`配置文件，支持：

- 🔄 主网fork配置
- 🌐 多网络支持
- ⚡ 编译器优化
- 🧪 测试环境配置

## 文件说明

```
.
├── package.json          # 项目依赖配置
├── hardhat.config.js     # Hardhat配置文件
├── .env.example          # 环境变量模板
├── fork-control.sh       # 控制脚本
├── hardhat_node.log      # 节点日志（运行时生成）
├── .hardhat_node.pid     # 进程ID文件（运行时生成）
└── README.md            # 项目说明
```

## 使用示例

### 启动节点

```bash
./fork-control.sh start
```

输出示例：
```
检查系统依赖...
✓ Node.js 已安装: v18.17.0
✓ npm 已安装: 9.6.7
✓ Hardhat 已安装: 2.19.0
启动 Hardhat fork 节点...
✓ 节点启动成功!
PID: 12345
端口: 8545
日志文件: hardhat_node.log
RPC URL: http://127.0.0.1:8545
```

### 查看状态

```bash
./fork-control.sh status
```

### 连接到fork节点

节点启动后，您可以：

1. **使用Hardhat控制台**：
   ```bash
   npx hardhat console --network localhost
   ```

2. **在代码中连接**：
   ```javascript
   const { ethers } = require("ethers");
   const provider = new ethers.JsonRpcProvider("http://127.0.0.1:8545");
   ```

3. **使用MetaMask**：
   - 网络名称: Hardhat Fork
   - RPC URL: http://127.0.0.1:8545
   - 链ID: 1337
   - 货币符号: ETH

## 常见问题

### Q: 如何获取Infura API密钥？

A: 
1. 访问 [infura.io](https://infura.io)
2. 创建免费账户
3. 创建新项目
4. 复制项目的API密钥

### Q: 节点启动失败怎么办？

A: 
1. 检查`.env`文件配置
2. 确保RPC URL有效
3. 查看日志文件：`cat hardhat_node.log`
4. 检查端口是否被占用：`netstat -tln | grep 8545`

### Q: 如何修改fork的区块号？

A: 在`.env`文件中设置`FORK_BLOCK_NUMBER`为具体的区块号。

### Q: 脚本没有执行权限？

A: 运行 `chmod +x fork-control.sh` 给脚本添加执行权限。

## 高级用法

### 自定义npm脚本

```bash
# 启动fork节点
npm run fork

# 连接到本地节点
npm run console

# 编译合约
npm run compile
```

### 在代码中使用

```javascript
// 连接到fork节点
const { ethers } = require("hardhat");

async function main() {
    // 获取fork的账户
    const [signer] = await ethers.getSigners();
    console.log("Account:", signer.address);
    
    // 查看余额
    const balance = await signer.getBalance();
    console.log("Balance:", ethers.utils.formatEther(balance), "ETH");
}

main();
```

## 故障排除

如果遇到问题，请按以下步骤排查：

1. **检查系统依赖**：`./fork-control.sh start`会自动检查
2. **查看详细日志**：`./fork-control.sh logs`
3. **重启节点**：`./fork-control.sh restart`
4. **检查网络连接**：确保能访问以太坊RPC端点

## 许可证

MIT License 