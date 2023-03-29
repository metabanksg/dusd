// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

/**
 * @title Upgradable MB Master Contract for Ethereum
 * @author MetaBank SG
 * @notice This smart contract is used to handle MB liquidity pool and user balances
 * @custom:experimental version 1.0.0
 */

import "./interfaces/IMbMaster.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract MbMaster is IMbMaster, OwnableUpgradeable {}
