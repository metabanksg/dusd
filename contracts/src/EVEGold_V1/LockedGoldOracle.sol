// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./EVEGold.sol";


// 调节任意锁定的黄金总供应量的简单合约
// 给定时间，以便缓存合约不能过度铸造代币
contract LockedGoldOracle is Ownable {

    using SafeMath for uint256;

    uint256 private _lockedGold;
    address private _eveContract;

    event LockEvent(uint256 amount);
    event UnlockEvent(uint256 amount);

    function setEVEContract(address eveContract) external onlyOwner {
        _eveContract = eveContract;
    }

    function lockAmount(uint256 amountGrams) external onlyOwner {
        _lockedGold = _lockedGold.add(amountGrams);
        emit LockEvent(amountGrams);
    }

    // 只有在离开时才能解锁金币数量
    // 锁仓金币总量大于等于流通中的代币数量
    function unlockAmount(uint256 amountGrams) external onlyOwner {
        _lockedGold = _lockedGold.sub(amountGrams);
        require(_lockedGold >= EVEGold(_eveContract).totalCirculation());
        emit UnlockEvent(amountGrams);
    }

    function lockedGold() external view returns(uint256) {
        return _lockedGold;
    }

    function eveContract() external view returns(address) {
        return _eveContract;
    }
}
