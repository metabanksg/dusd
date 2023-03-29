// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "./interfaces/IERC20Factory.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./PermittableToken.sol";

/**
 * @title Contract for ERC20 Token Factory
 * @author MetaBank SG
 * @notice This smart contract is an interface to manage deployed tokens on Fisco
 * @custom:experimental version 1.0.0
 */

contract ERC20Factory is IERC20Factory, OwnableUpgradeable {
    address[] private deployedTokens;

    function initialize() external initializer {
        __Ownable_init();
    }

    function deployTokens(
        address _owner,
        string memory _tokenName,
        string memory _tokenSymbol,
        uint8 _tokenDecimals,
        uint256 _tokenInitSupply
    ) external onlyOwner {
        PermittableToken newToken = new PermittableToken(
            _owner,
            _tokenName,
            _tokenSymbol,
            _tokenDecimals,
            _tokenInitSupply
        );
        deployedTokens.push(address(newToken));
    }

    function allTokens() external view onlyOwner returns (address[] memory) {
        return deployedTokens;
    }

    function findToken(
        address _tokenAddr
    ) external view onlyOwner returns (string memory) {
        IERC20Metadata token = IERC20Metadata(_tokenAddr);
        return token.name();
    }
}
