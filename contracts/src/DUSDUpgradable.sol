// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

/**
 * @title Upgradable DUSD smart contract for Ethereum & Fisco BCOS
 * @author MetaBank SG
 * @notice This is the official upgradable smart contract for DUSD ERC20 Tokens on Fisco
 * @custom:experimental version 1.0.0
 */

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract DUSDUpgradable is ERC20PermitUpgradeable, OwnableUpgradeable {
    /// @notice initialize function, can only be used once to initialize owner, ERC20 token and initial supply
    /// @param _initSupply is used to determine DUSD initial supply
    function intialize(
        uint256 _initSupply,
        string memory tokenName,
        string memory tokenSymbol
    ) external initializer {
        __Ownable_init();
        __ERC20_init(tokenName, tokenSymbol);
        _mint(msg.sender, _initSupply);
    }

    /// @notice only owner allowed to mint tokens
    /// @param _to is the reciever of the newly minted tokens
    /// @param _amount is the amount of newly minted tokens
    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }

    /// @notice only owner allowed to burn tokens
    /// @param _from is the address owner whose tokens are being burned
    /// @param _amount is the amount of tokens being burned
    function burn(address _from, uint256 _amount) external onlyOwner {
        _burn(_from, _amount);
    }
}
