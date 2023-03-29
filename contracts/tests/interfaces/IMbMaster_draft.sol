// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

/**
 * @title Interface for MB Master Contract on Ethereum
 * @author MetaBank SG
 * @notice This smart contract is an interface to handle MB liquidity pool and user balances
 * @custom:experimental version 1.0.0
 */

interface IMbMaster {
    // =============================================
    //                  MEMORY
    // =============================================

    /// @notice struct to define a user's balance, EOA and verify if user is MB user.
    /// @param tokenBalance stores user's total wallet value converted to USD
    /// @param eoa stores user's externally owned wallet as a whitelist for future transfers
    /// @param isMBUser verifies if user is a MB wallet user
    struct UserStruct {
        address[] tokens;
        mapping(address => TokenBalance) tokenBalance;
        address eoa;
        bool isMBUser;
        uint256 dusdBalance;
    }

    struct TokenBalance {
        string name;
        uint256 balance;
    }

    // =============================================
    //                  EVENTS
    // =============================================

    event Initialized(address owner);
    event NewUserRegistered(address _newUser);
    event EOAChanged(address _oldAddress, address _newAddress);
    event AdminTokenWithdrawn(
        string tokenName,
        address tokenAddr,
        uint256 _amount
    );
    event AdminEthWithdrawn(uint256 amount);
    event UserTokenDeposited(
        string tokenName,
        address tokenAddr,
        address mbWallet,
        address eoa,
        uint256 amount
    );
    event UserFiatDeposited(address mbWallet, uint256 amount);
    event UserTokenWithdrawn(
        string tokenName,
        address tokenAddr,
        address mbWallet,
        address eoa,
        uint256 amount
    );

    /// @notice empty receive function to allow smart contract to hold Native Token(Ethereum)
    receive() external payable;

    // =============================================
    //                  INITIALIZER
    // =============================================

    /// @notice initializer can only be executed once upon deployment, will not be re-initiated after contract upgrades
    /// @dev initializes ownership to address deployer
    function initialize() external;

    // =============================================
    //              EXTERNAL FUNCTIONS
    // =============================================

    /// @notice register's new user by storing MB Wallet address into smart contract and enabling "isMBUser" to true
    /// @dev only owner can access registerNewUser() function
    /// @param _mbWalletAddress = user's new MB wallet address
    function registerNewUser(address _mbWalletAddress) external;

    /// @notice allow for users to re-assign their Externally Owned Wallet, would require a lock down period for security purposes
    /// @dev only MB wallet users can use showUserBalance() function
    /// @param _newEoa new Externally Owned Wallet, must not be the same as the current EOA address, otherwise revert transaction
    function changeEoa(address _newEoa) external;

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
    /// @param _mbWallet = MB Wallet Address
    /// @param _tokenAddr = token Address, would need some form of authentication to verify address belongs to official stablecoin
    /// @param _eoa = user's externally owned account
    /// @param _amount ? = amount in USD value, meaning every swap requires an oracle or subgraph to receive price feed to convert amount from USD
    function depositTokens(
        address _mbWallet,
        address _tokenAddr,
        address _eoa,
        uint256 _amount
    ) external;

    /// @notice deposits value into MB Wallet as user uses fiat to get DUSD tokens on Laos Chain
    /// @param _mbWallet = MB wallet Address
    /// @param _amount = amount in USD value
    function depositFiat(address _mbWallet, uint256 _amount) external;

    /// @notice allow users to withdraw or swap from DUSD to stablecoins based on the amount in USD that users deposited into MB Master Contract
    /// @dev only MB wallet users can use withdraw() function, otherwise revert transaction
    /// @param _mbWallet = MB wallet Address
    /// @param _eoa = user's Externally Owned Wallet, needs to be whitelisted in balances[msg.sender].Eoa otherwise revert
    /// @param _tokenAddr = token Address, would need some form of authentication to verify address belongs to official stablecoin
    /// @param _amount ? = amount in USD value, meaning every swap requires an oracle or subgraph to receive price feed to convert amount from USD
    function withdrawTokens(
        address _mbWallet,
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

    /// @notice displays user balance on mobile app, Note: user will not see their MBWallet address, just balance and EOAWallet
    /// @dev only MB wallet users can use showUserDusdBalance() function
    /// @param _mbWallet = MB wallet address
    /// @return uint256 = Balance of DUSD in value
    function showUserDusdBalance(
        address _mbWallet
    ) external view returns (uint256);

    /// @notice display user current registered Externally Owned Account
    /// @dev only MB wallet users can use showUserEoa() function
    /// @param _mbWallet = MB wallet address
    /// @return address = user's current EOA address
    function showUserEoa(address _mbWallet) external view returns (address);

    /// @notice checks if user is already a MB user by verifying if balances[msg.sender].isMBUser is true or false
    /// @param _mbWallet = MB wallet address
    function checkExistingUser(address _mbWallet) external view returns (bool);
}
