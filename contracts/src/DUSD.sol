// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

/**
 * @title DUSD smart contract for Ethereum and TRON
 * @author MetaBank SG
 * @notice This is the official smart contract for DUSD ERC20 Tokens
 * @custom:experimental Version 1.0
 */

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DUSD is ERC20, Ownable {
    constructor(uint256 _initialSupply) ERC20("DUSD", "DUSD") {
        _mint(msg.sender, _initialSupply * 10 ** decimals());
    }

    /// @notice based on Stablecoin best practices, uses the decimals of 6
    /// @dev OZ states that this is for display purposes only, will not affect arithmetic of the contract
    /// @return uint8 = the decimal places that will be displayed
    function decimals() public pure override returns (uint8) {
        return 6;
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
