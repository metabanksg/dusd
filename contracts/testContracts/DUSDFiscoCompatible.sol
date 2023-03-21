// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.4.25;

/** 
 * @title DUSD smart contract for Fisco BCOS 
 * @author MetaBank SG
 * @notice This is the official smart contract for DUSD ERC20 Tokens on Fisco due to solidity version difference
 * @dev use this to deploy on Fisco BCOS because it uses solidity v0.6.10 which is supported
 * @dev experimental version 1.1.0 not officially audited and should be used with caution
 */

import "../src/OpenZeppelin/ERC20.sol";
import "../src/OpenZeppelin/ERC20Detailed.sol";
import "../src/OpenZeppelin/Ownable.sol";

contract DUSDFiscoCompatibleFlatten is ERC20, ERC20Detailed, Ownable {

    /// @notice decimals have been changed to 6 to align with stablecoin standards
    /// @param _initialSupply to provide an initial suppply for DUSD
     constructor(uint256 _initialSupply) ERC20Detailed("DUSD", "DUSD", 6) public {
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