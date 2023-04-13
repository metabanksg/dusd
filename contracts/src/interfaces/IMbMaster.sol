// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

/**
 * @title Interface for MB Master Contract on Ethereum
 * @author MetaBank SG
 * @notice This smart contract is an interface to handle MB liquidity pool and user balances
 * @custom:experimental version 1.0.0
 */

interface IMBMaster {
    // =============================================
    //                  ERRORS
    // =============================================

    error AlreadyRegisteredUser();
    error Unpaused();
    error InsufficientFunds(uint256 request, uint256 balance);
    error IncorrectEOA();

    // =============================================
    //                  MEMORY
    // =============================================

    struct UserStruct {
        address[] tokens;
        mapping(address => TokenBalance) tokenBalance;
        uint256 fiatBalance;
        bool isMBUser;
    }

    struct TokenBalance {
        string name;
        uint256 balance;
    }

    // =============================================
    //                  EVENTS
    // =============================================

    event Initialized(address owner);

    // =============================================
    //                INITIALIZER
    // =============================================

    /// @notice initializer can only be executed once upon deployment, will not be re-initiated after contract upgrades
    /// @dev  *IMPORTANT* initializes ownership to address deployer immediately upon deployment
    function initialize() external;

    // =============================================
    //              EXTERNAL FUNCTIONS
    // =============================================

    /// @notice stops all transactions from taking place, which includes withdraw and deposit due to security issues
    /// @dev only owner can pause smart contract
    function pause() external;

    /// @notice resumes all transactions as risks have been averted
    /// @dev only owner can unpause smart contract
    function unpause() external;

    /// @notice allows for owner to withdraw tokens from this smart contract
    /// @dev only owner can withdraw tokens from this smart contract
    /// @param _tokenAddr = token address used to attach to IERC20 Interface
    /// @param _amount = amount of tokens to withdraw
    function adminTokenWithdraw(address _tokenAddr, uint256 _amount) external;

    /// @notice allows for owner to withdraw ether from this smart contract
    /// @param _amount = amount of ether to withdraw
    function adminEthWithdraw(uint256 _amount) external;

    /// @notice allow users to top up their MB Wallets with stablecoins or swap stablecoins to DUSD on Laos Chain, equalevant to Top Up on mobile app
    /// @param _tokenAddr = token Address, would need some form of authentication to verify address belongs to official stablecoin
    /// @param _amount ? = amount in USD value, meaning every swap requires an oracle or subgraph to receive price feed to convert amount from USD
    function depositTokens(address _tokenAddr, uint256 _amount) external;

    /// @notice allow users to withdraw tokens
    /// @param _eoa = user's Externally Owned Wallet, needs to be whitelisted in balances[msg.sender].Eoa otherwise revert
    /// @param _tokenAddr = token Address, would need some form of authentication to verify address belongs to official stablecoin
    /// @param _amount ? = amount in USD value, meaning every swap requires an oracle or subgraph to receive price feed to convert amount from USD
    function withdrawTokens(
        address _eoa,
        address _tokenAddr,
        uint256 _amount
    ) external;

    // =============================================
    //           EXTERNAL VIEW FUNCTIONS
    // =============================================

    /// @notice displays user balance on mobile app, Note: user will not see their MBWallet address, just balance and EOAWallet
    /// @dev only MB wallet users can use showUserTokenBalance() function
    /// @param _mbWallet = MB wallet address
    /// @return TokenBalance[] = Struct of token balance
    function showUserTokenBalance(
        address _mbWallet
    ) external view returns (TokenBalance[] memory);
}
