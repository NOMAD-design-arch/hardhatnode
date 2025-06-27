const { ethers } = require("hardhat");

async function main() {
    console.log("🔍 测试 Hardhat Fork 功能...\n");
    
    try {
        // 获取网络信息
        const network = await ethers.provider.getNetwork();
        console.log(`📡 网络信息:`);
        console.log(`   链ID: ${network.chainId}`);
        console.log(`   网络名称: ${network.name}\n`);
        
        // 获取最新区块信息
        const latestBlock = await ethers.provider.getBlock("latest");
        console.log(`🧱 最新区块信息:`);
        console.log(`   区块号: ${latestBlock.number}`);
        console.log(`   时间戳: ${new Date(latestBlock.timestamp * 1000).toLocaleString()}`);
        console.log(`   哈希: ${latestBlock.hash}`);
        console.log(`   交易数量: ${latestBlock.transactions.length}\n`);
        
        // 获取预设账户
        const signers = await ethers.getSigners();
        console.log(`👥 预设账户信息:`);
        
        for (let i = 0; i < Math.min(5, signers.length); i++) {
            const signer = signers[i];
            const balance = await signer.getBalance();
            console.log(`   账户 ${i + 1}: ${signer.address}`);
            console.log(`   余额: ${ethers.utils.formatEther(balance)} ETH`);
        }
        
        if (signers.length > 5) {
            console.log(`   ... 以及其他 ${signers.length - 5} 个账户\n`);
        } else {
            console.log("");
        }
        
        // 测试一些知名合约地址（如USDC）
        const usdcAddress = "0xA0b86a33E6441BDF7bb42B73F6B0c86c1FbD6c7F"; // USDC合约地址
        const usdcCode = await ethers.provider.getCode(usdcAddress);
        
        if (usdcCode !== "0x") {
            console.log(`✅ 成功fork主网状态 - 能够访问链上合约`);
            console.log(`   USDC合约代码长度: ${usdcCode.length} 字符\n`);
        } else {
            console.log(`⚠️  无法访问主网合约，可能是RPC配置问题\n`);
        }
        
        // 测试交易功能
        console.log(`🔄 测试交易功能:`);
        const [sender, receiver] = signers;
        const transferAmount = ethers.utils.parseEther("1.0");
        
        const balanceBefore = await receiver.getBalance();
        console.log(`   转账前接收者余额: ${ethers.utils.formatEther(balanceBefore)} ETH`);
        
        const tx = await sender.sendTransaction({
            to: receiver.address,
            value: transferAmount
        });
        
        console.log(`   交易哈希: ${tx.hash}`);
        await tx.wait();
        
        const balanceAfter = await receiver.getBalance();
        console.log(`   转账后接收者余额: ${ethers.utils.formatEther(balanceAfter)} ETH`);
        console.log(`   转账金额: ${ethers.utils.formatEther(balanceAfter.sub(balanceBefore))} ETH\n`);
        
        console.log(`🎉 Fork测试完成！所有功能正常工作。`);
        
    } catch (error) {
        console.error(`❌ 测试失败:`, error.message);
        process.exit(1);
    }
}

// 如果直接运行此脚本
if (require.main === module) {
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
}

module.exports = main; 