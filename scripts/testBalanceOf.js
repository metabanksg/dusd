// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {

    const address = `0x1563C040b5fa86fFAfBdeB17723de88EcBCEd24E`
    const wallet = `0xA57100ab84701e890e0b707262D2b0da6F66dB6C`

  // try to retrieve balance of DUSD from EOD wallet 
  try {

    const DUSDFactory = await hre.ethers.getContractFactory("DUSD");
    const instance = DUSDFactory.attach(address)

    let balance = await instance.balanceOf(`${wallet}`)

   console.log(hre.ethers.utils.formatEther(balance))
  } catch (err) {
    console.error(err);
  }
  
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
