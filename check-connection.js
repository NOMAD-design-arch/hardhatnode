const { ethers } = require("hardhat");

async function checkConnection() {
    console.log("🔍 检查网络连接...\n");
    
    try {
        // 检查网络配置
        const network = await ethers.provider.getNetwork();
        console.log(`✅ 网络连接成功`);
        console.log(`   链ID: ${network.chainId}`);
        console.log(`   网络名称: ${network.name}\n`);
        
        // 检查最新区块
        const blockNumber = await ethers.provider.getBlockNumber();
        console.log(`✅ 能够获取区块信息`);
        console.log(`   最新区块号: ${blockNumber}\n`);
        
        // 检查账户
        const signers = await ethers.getSigners();
        console.log(`✅ 获取到 ${signers.length} 个预设账户`);
        
        if (signers.length > 0) {
            const firstAccount = signers[0];
            const balance = await ethers.provider.getBalance(firstAccount.address);
            console.log(`   第一个账户: ${firstAccount.address}`);
            console.log(`   余额: ${ethers.formatEther(balance)} ETH\n`);
        }
        
        // 检查是否连接到fork
        try {
            // 尝试获取一个已知的主网合约
            const wethAddress = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"; // WETH合约
            const code = await ethers.provider.getCode(wethAddress);
            if (code !== "0x") {
                console.log(`✅ 成功连接到主网fork`);
                console.log(`   WETH合约代码存在，长度: ${code.length} 字符\n`);
            } else {
                console.log(`⚠️  可能未正确fork主网或RPC配置有问题\n`);
            }
        } catch (error) {
            console.log(`⚠️  检查主网状态时出错: ${error.message}\n`);
        }
        
        console.log(`🎉 基本连接检查完成！`);
        
    } catch (error) {
        console.error(`❌ 连接检查失败: ${error.message}`);
        console.error(`\n💡 可能的解决方案:`);
        console.error(`   1. 确保节点正在运行: ./fork-control.sh status`);
        console.error(`   2. 检查.env文件中的配置`);
        console.error(`   3. 确保MAINNET_RPC_URL有效`);
        console.error(`   4. 重启节点: ./fork-control.sh restart`);
        process.exit(1);
    }
}

if (require.main === module) {
    checkConnection()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
}

module.exports = checkConnection; 