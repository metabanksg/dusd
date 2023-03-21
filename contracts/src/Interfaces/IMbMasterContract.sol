// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

/**
 * @title Upgradable MB Master Contract for Ethereum
 * @author MetaBank SG
 * @notice This smart contract is used to handle MB liquidity pool and user balances
 * @custom:experimental version 1.0.0
 */

interface IMbMasterContract {
    /// @notice struct to define a user's balance, EOA and verify if user is MB user.
    /// @param MBWallet stores user's MB wallet address
    /// @param Balance stores user's total wallet value converted to USD
    /// @param Eoa stores user's externally owned wallet as a whitelist for future transfers
    /// @param isMBUser verifies if user is a MB wallet user
    struct User {
        address MBWallet;
        uint256 Balance;
        address Eoa;
        bool isMBUser;
    }

    /// @notice empty receive function to allow smart contract to hold Native Token(Ethereum)
    receive() external payable;

    /// @notice initializer can only be executed once upon deployment, will not be re-initiated after contract upgrades
    /// @dev initializes ownership to address deployer
    function initialize() external;

    /// @notice register's new user by storing MB Wallet address into smart contract and enabling "isMBUser" to true
    /// @dev only owner can access registerNewUser() function
    /// @param _mbWalletAddress = user's new MB wallet address
    function registerNewUser(address _mbWalletAddress) external;

    /// @notice allow for users to re-register their Externally Owned Wallet, would require a lock down period for security purposes
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
    /// @param _to = transfers tokens to this address
    /// @param _tokenAddr = token address used to attach to IERC20 Interface
    /// @param _amount = amount of tokens to withdraw
    function adminTokenWithdraw(
        address _to,
        address _tokenAddr,
        uint256 _amount
    ) external;

    /// @notice allows for owner to withdraw ether from this smart contract
    /// @param _to = transfers tokens to this address
    /// @param _amount = amount of ether to withdraw
    function adminEthWithdraw(address _to, uint256 _amount) external;

    /// @notice allow users to top up their MB Wallets with stablecoins or swap stablecoins to DUSD on Laos Chain, equalevant to Top Up on mobile app
    /// @dev only MB wallet users can use showUserBalance() function
    /// @param _mbWallet = MB Wallet Address
    /// @param _tokenAddr = token Address, would need some form of authentication to verify address belongs to official stablecoin
    /// @param _amount ? = amount in USD value, meaning every swap requires an oracle or subgraph to receive price feed to convert amount from USD
    function depositWithEoa(
        address _mbWallet,
        address _tokenAddr,
        uint256 _amount
    ) external;

    /// @notice deposits value into MB Wallet as user uses fiat to get DUSD tokens on Laos Chain
    /// @param _mbWallet = MB wallet Address
    /// @param _amount = amount in USD value
    function depositWithFiat(address _mbWallet, uint256 _amount) external;

    /// @notice allow users to withdraw or swap from DUSD to stablecoins based on the amount in USD that users deposited into MB Master Contract
    /// @dev only MB wallet users can use withdraw() function, otherwise revert transaction
    /// @param _eoa = user's Externally Owned Wallet, needs to be whitelisted in balances[msg.sender].Eoa otherwise revert
    /// @param _tokenAddr = token Address, would need some form of authentication to verify address belongs to official stablecoin
    /// @param _amount ? = amount in USD value, meaning every swap requires an oracle or subgraph to receive price feed to convert amount from USD
    function withdraw(
        address _eoa,
        address _tokenAddr,
        uint256 _amount
    ) external;

    /// @notice displays user balance on mobile app, Note: user will not see their MBWallet address, just balance and EOAWallet
    /// @dev only MB wallet users can use showUserBalance() function
    /// @param _mbWallet = MB wallet address
    /// @return MBWallet = MB Wallet address
    /// @return Balance = total balance in USD
    /// @return EOAWallet = Externally Owned Wallet not equals to MB wallet
    function showUserBalance(
        address _mbWallet
    )
        external
        view
        returns (address MBWallet, uint256 Balance, address EOAWallet);

    /// @notice checks if user is already a MB user by verifying if balances[msg.sender].isMBUser is true or false
    /// @param _mbWallet = MB wallet address
    function checkExistingUser(address _mbWallet) external view returns (bool);
}
