const hre = require('hardhat')

async function main() {
  const address = ``
  const wallet = ``

  // try to retrieve balance of DUSD from EOD wallet
  try {
    const DUSDFactory = await hre.ethers.getContractFactory('DUSDUpgradable')
    const instance = DUSDFactory.attach(address)

    let balance = await instance.balanceOf(`${wallet}`)

    console.log(hre.ethers.utils.formatEther(balance))
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
