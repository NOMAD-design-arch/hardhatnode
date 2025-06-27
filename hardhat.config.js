require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

const { MAINNET_RPC_URL, FORK_PORT, FORK_BLOCK_NUMBER, NETWORK_ID, GAS_LIMIT, GAS_PRICE, PRIVATE_KEY, ACCOUNTS_COUNT, ACCOUNTS_BALANCE, FORK_HOST } = process.env;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    hardhat: {
      chainId: parseInt(NETWORK_ID) || 1337,
      forking: {
        url: MAINNET_RPC_URL,
        blockNumber: FORK_BLOCK_NUMBER ? parseInt(FORK_BLOCK_NUMBER) : undefined,
      },
      gas: parseInt(GAS_LIMIT) || 30000000,
      gasPrice: parseInt(GAS_PRICE) || 8000000000,
      accounts: {
        count: parseInt(ACCOUNTS_COUNT) || 20,
        accountsBalance: `${ACCOUNTS_BALANCE || 10000}000000000000000000` // ETH in wei
      }
    },
    localhost: {
      url: `http://${FORK_HOST || '127.0.0.1'}:${FORK_PORT || 8545}`,
      chainId: parseInt(NETWORK_ID) || 1337
    },
    mainnet: {
      url: MAINNET_RPC_URL,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
      chainId: 1
    }
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  mocha: {
    timeout: 40000
  }
}; 