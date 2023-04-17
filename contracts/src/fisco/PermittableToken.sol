// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

/**
 * @title Contract for ERC20 Compliant Permittable Token
 * @author MetaBank SG
 * @notice This smart contract will create a ERC20 Compliant Permittable Token
 * @custom:experimental version 1.0.0
 */

contract PermittableToken is ERC20Permit, Ownable {
    /// @notice used to multiply with initial supply and display when decimals() is triggered
    uint8 immutable DECIMALS;

    /// @notice constructor function to initiate tokens upon deployment
    /// @param _owner = owner of this tokens contract
    /// @param _tokenName = token name
    /// @param _tokenSymbol = token symbol, could be the same as token name
    /// @param _tokenDecimals = token decimal places, best practices are ERC20 = 18, Stablecoin = 6
    /// @param _tokenInitSupply = token initial supply upon deployment
    constructor(
        address _owner,
        string memory _tokenName,
        string memory _tokenSymbol,
        uint8 _tokenDecimals,
        uint256 _tokenInitSupply
    ) ERC20(_tokenName, _tokenSymbol) ERC20Permit(_tokenName) {
        _transferOwnership(_owner);
        DECIMALS = _tokenDecimals;
        _mint(_owner, _tokenInitSupply * 10 ** DECIMALS);
    }

    /// @notice only owner allowed to mint tokens
    /// @param _to is the reciever of the newly minted tokens
    /// @param _amount is the amount of newly minted tokens
    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }

    /// @notice only owner allowed to burn tokens, requires _from to have enough balance to burn
    /// @param _from is the address owner whose tokens are being burned
    /// @param _amount is the amount of tokens being burned
    function burn(address _from, uint256 _amount) external onlyOwner {
        _burn(_from, _amount);
    }

    /// @notice a display only function to display how many decimal places this ERC20 token has
    /// @return uint8 the decimal places of this current ERC20 token
    function decimals() public view override returns (uint8) {
        return DECIMALS;
    }
}
