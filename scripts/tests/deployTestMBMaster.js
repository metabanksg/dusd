const { ethers, upgrades } = require('hardhat')

async function main() {
  // deploys proxy DUSD smart contract and initializes the smart contract
  // Note that initialization can only be executed once and cannot be initialized again after subsequent upgrades
  try {
    const mbMasterFactory = await ethers.getContractFactory('MbMaster')
    const mbMaster = await mbMasterFactory.deploy(
      '0x1563C040b5fa86fFAfBdeB17723de88EcBCEd24E'
    )
    await mbMaster.deployed()

    // latest deployed proxy contract address is 0x446600d39EAc7Ec352BEB64C4A31457D43C35cf4 [Sepolia: test]
    console.log(
      `Successfully deployed to contract address: ${mbMaster.address}`
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
