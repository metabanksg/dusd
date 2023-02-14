// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  
  // To determine initial supply multiply by 18 decimals based on Ethereum
  const initialSupply = 1_000_000 * 10**18

  try {

    const DUSDFactory = await hre.ethers.getContractFactory("DUSD");
    const DUSD = await DUSDFactory.deploy(initialSupply);
    await DUSD.deployed();

    console.log(`Successfully deployed to contract address: ${DUSD.address}`);
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
