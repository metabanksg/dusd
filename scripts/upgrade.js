const { ethers, upgrades } = require('hardhat')

async function main() {
  // provide the existing proxy instance address
  const instanceAddress = ''

  try {
    // retrieve new DUSD smart contract variant
    const newDUSD = await ethers.getContractFactory('')

    // deploy upgraded contract and determine new upgraded deployment
    // @param _instance.address = current deployed proxy address
    // @param newDUSD = new version of the DUSD smart contract
    const upgraded = await upgrades.upgradeProxy(instanceAddress, newDUSD)

    // prints the proxy address of the newly upgraded smart contract
    console.log(`DUSD proxy successfully upgraded! ${upgraded.address}`)
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
