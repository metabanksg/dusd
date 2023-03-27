const { ethers, upgrades } = require('hardhat')

async function main() {
  // deploys proxy MBMaster smart contract and initializes the smart contract
  // Note that initialization can only be executed once and cannot be initialized again after subsequent upgrades
  try {
    const MbMAsterFactory = await ethers.getContractFactory('MBMaster')
    const MbMaster = await upgrades.deployProxy(MbMAsterFactory, {
      initializer: 'initialize',
    })
    await MbMaster.deployed()

    // latest deployed proxy contract address is ??? [Goerli: test]
    console.log(
      `Successfully deployed to contract address: ${MbMaster.address}`
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
