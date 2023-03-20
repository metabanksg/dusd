const { ethers, upgrades } = require('hardhat')

async function main() {
  // define how much to mint for initial supply, example 1 million
  const initialSupply = hre.ethers.utils.parseEther(`${1_000_000}`)

  // deploys proxy DUSD smart contract and initializes the smart contract
  // Note that initialization can only be executed once and cannot be initialized again after subsequent upgrades
  try {
    const DUSDFactory = await ethers.getContractFactory('DUSDUpgradable')
    const DUSD = await upgrades.deployProxy(DUSDFactory, [initialSupply])
    await DUSD.deployed()

    // latest deployed proxy contract address is 0x8B893b7F6283B8Df351c11c37039e2dd96aB9B2D [Goerli: test]
    console.log(`Successfully deployed to contract address: ${DUSD.address}`)
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
