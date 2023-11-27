// 部署流程：
// 1、先部署LockedGoldOracle取得合约地址，再部署EVEGold。
// 2、设置LockedGoldOracle下的EVEGold合约地址

// 测试流程：
// 所有交易金额均不用加小数位
// 1、设置 LockedGoldOracle的lockAmount锁仓金额，再EVEGold中增加代币addBackedTokens（这里判断不能超过锁仓金额）这里有一个_backedTreasury流通仓和_unbackedTreasury非流通仓
// 2、转账流程 通过_backedTreasury地址转账给用户
// 3、收取存储费 按天数 0.25%/年 收取
// 4、赎回/得到实物黄金（不做销毁）进入_unbackedTreasury非流通库，Owner增加代币时进入_backedTreasury流通仓
const { ethers } = require('hardhat')
//owner = '0x5B38Da6a701c568545dCfcB03FcB875f56beddC4'
async function main() {
  try {
    const LockedGoldOracleFactory = await ethers.getContractFactory('LockedGoldOracle')
    const LockedGoldOracle = await LockedGoldOracleFactory.deploy()
    await LockedGoldOracle.deployed();

    console.log(`Successfully deployed to contract address: ${LockedGoldOracle.address}`)
  } catch (err) {
    console.error(err)
  }
  // LockedGoldOracle.addres = '0xd9145CCE52D386f254917e481eB44e9943F39138';
  try {
    const EVEGoldFactory = await ethers.getContractFactory('EVEGold')
    const EVEGold = await EVEGoldFactory.deploy(
        '0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2',  //UNBACKEDTREASURY
        '0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db',  //BACKEDTREASURY
        '0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB',  //FEEADDRESS
        '0xd9145CCE52D386f254917e481eB44e9943F39138'   //ORACLE
    )

    await EVEGold.deployed();

    console.log(`Successfully deployed to contract address: ${EVEGold.address}`)
  } catch (err) {
    console.error(err)
  }
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
