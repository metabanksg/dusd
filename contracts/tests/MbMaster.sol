// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

/**
 * @title Upgradable MB Master Contract for Ethereum
 * @author MetaBank SG
 * @notice This smart contract is used to handle MB liquidity pool and user balances
 * @custom:experimental version 1.1.0
 */

// import "../interfaces/IMBMaster";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@opengsn/contracts/src/ERC2771Recipient.sol";

contract MbMaster is ERC2771Recipient, Ownable {
    using SafeERC20 for IERC20Metadata;

    struct storedSchema {
        address user;
        string someStr;
    }

    storedSchema[] private stored;

    constructor(address _forwarder) {
        _setTrustedForwarder(_forwarder);
    }

    function storeAndReturnMsg(
        string calldata _message
    ) external returns (storedSchema memory) {
        storedSchema memory newMessage = storedSchema(_msgSender(), _message);
        stored.push(newMessage);
        return newMessage;
    }

    function displayStored() external view returns (storedSchema[] memory) {
        return stored;
    }

    function _msgSender()
        internal
        view
        override(Context, ERC2771Recipient)
        returns (address sender)
    {
        sender = ERC2771Recipient._msgSender();
    }

    function _msgData()
        internal
        view
        override(Context, ERC2771Recipient)
        returns (bytes calldata)
    {
        return ERC2771Recipient._msgData();
    }
}
