// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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
        _mint(msg.sender, _initialSupply);
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