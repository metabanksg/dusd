require("@nomicfoundation/hardhat-toolbox")
require('dotenv').config()

module.exports = {
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 9999
      }
    }
  },
  networks: {
    goerli: {
      url: process.env.GOERLI_URL,
      accounts:
        [process.env.PRIVATE_KEY],
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: 'USD',
    token: 'ETH'
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
}