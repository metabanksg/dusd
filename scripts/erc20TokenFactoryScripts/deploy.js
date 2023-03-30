const { ethers } = require('hardhat')

async function main() {
  // deploys ERC20Factory smart contract
  try {
    const TokenFactoryDeployer = await ethers.getContractFactory('ERC20Factory')
    const TokenFactory = await TokenFactoryDeployer.deploy()
    await TokenFactory.deployed()

    // latest deployed contract address is [Goerli: test]
    console.log(
      `Successfully deployed to contract address: ${TokenFactory.address}`
    )
  } catch (err) {
    console.error(err)
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
