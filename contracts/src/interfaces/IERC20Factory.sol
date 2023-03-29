// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

/**
 * @title Interface for ERC20 Token Factory
 * @author MetaBank SG
 * @notice This smart contract is an interface to manage deployed tokens on Fisco
 * @custom:experimental version 1.0.0
 */

interface IERC20Factory {
    function initialize() external;

    function deployTokens(
        address _owner,
        string memory _tokenName,
        string memory _tokenSymbol,
        uint8 _tokenDecimals,
        uint256 _tokenInitSupply
    ) external;

    function allTokens() external view returns (address[] memory);

    function findToken(address _tokenAddr) external returns (string memory);
}
