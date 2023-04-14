// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

/**
 * @title Upgradable MB Master Contract for Ethereum
 * @author MetaBank SG
 * @notice This smart contract is used to handle MB liquidity pool and user balances
 * @custom:experimental version 1.0.0
 */

import "../interfaces/IMbMaster.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract MbMaster is IMbMaster, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

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

    /// @notice balances address refers to user's MB Wallet
    mapping(address => UserStruct) private user;
    bool public isPaused;

    // =============================================
    //                  MODIFIERS
    // =============================================

    modifier pausable() {
        require(isPaused == false, "paused");
        _;
    }

    modifier isMBUser() {
        require(user[msg.sender].isMBUser == true, "Not MB User");
        _;
    }

    /// @notice empty receive function to allow smart contract to hold Native Token(Ethereum)
    receive() external payable {}

    // =============================================
    //                  INITIALIZER
    // =============================================

    /// @notice initializer can only be executed once upon deployment, will not be re-initiated after contract upgrades.
    /// @dev initializes ownership to address deployer
    function initialize() external initializer {
        __Ownable_init();
    }

    // =============================================
    //              EXTERNAL FUNCTIONS
    // =============================================

    /// @notice register's new user by storing MB Wallet address into smart contract and enabling "isMBUser" to true
    /// @dev only owner can access registerNewUser() function
    /// @param _mbWalletAddress = user's new MB wallet address
    function registerNewUser(
        address _mbWalletAddress
    ) external onlyOwner pausable {
        if (_checkExistingUser(_mbWalletAddress) == true) {
            revert AlreadyRegisteredUser();
        }
        user[_mbWalletAddress].isMBUser = true;
        emit NewUserRegistered(_mbWalletAddress);
    }

    /// @notice allow for users to re-assign their Externally Owned Wallet, would require a lock down period for security purposes
    /// @dev only MB wallet users can use showUserBalance() function
    /// @param _newEoa new Externally Owned Wallet, must not be the same as the current EOA address, otherwise revert transaction
    function changeEoa(address _newEoa) external isMBUser pausable {
        address oldEoa = user[msg.sender].eoa;
        user[msg.sender].eoa = _newEoa;
        emit EOAChanged(oldEoa, _newEoa);
    }

    /// @notice stops all transactions from taking place, which includes withdraw and deposit due to security issues
    /// @dev only owner can pause smart contract
    function pause() external onlyOwner pausable {
        isPaused = true;
    }

    /// @notice resumes all transactions as risks have been averted
    /// @dev only owner can unpause smart contract
    function unpause() external onlyOwner {
        if (isPaused == false) {
            revert Unpaused();
        }
        isPaused = false;
    }

    /// @notice allows for owner to withdraw tokens from this smart contract
    /// @dev only owner can withdraw tokens from this smart contract
    /// @param _tokenAddr = token address used to attach to IERC20 Interface
    /// @param _amount = amount of tokens to withdraw
    function adminTokenWithdraw(
        address _tokenAddr,
        uint256 _amount
    ) external onlyOwner {
        string memory tokenName = IERC20MetadataUpgradeable(_tokenAddr).name();
        _withdraw(_tokenAddr, _amount);
        emit AdminTokenWithdrawn(tokenName, _tokenAddr, _amount);
    }

    /// @notice allows for owner to withdraw ether from this smart contract
    /// @param _amount = amount of ether to withdraw
    function adminEthWithdraw(uint256 _amount) external onlyOwner {
        _withdrawEth(_amount);
        emit AdminEthWithdrawn(_amount);
    }

    /// @notice allow users to top up their MB Wallets with stablecoins or swap stablecoins to DUSD on Laos Chain, equalevant to Top Up on mobile app
    /// @param _mbWallet = MB Wallet Address
    /// @param _tokenAddr = token Address, would need some form of authentication to verify address belongs to official stablecoin
    /// @param _amount ? = amount in USD value, meaning every swap requires an oracle or subgraph to receive price feed to convert amount from USD
    function depositTokens(
        address _mbWallet,
        address _tokenAddr,
        address _eoa,
        uint256 _amount
    ) external isMBUser pausable {
        IERC20MetadataUpgradeable tokens = IERC20MetadataUpgradeable(
            _tokenAddr
        );
        string memory tokenName = tokens.name();
        user[_mbWallet].tokens.push(_tokenAddr);
        user[_mbWallet].tokenBalance[_tokenAddr].name = tokenName;
        user[_mbWallet].tokenBalance[_tokenAddr].balance += _amount;
        /// @dev there is supposed to be a permit here before safeTransfer is executed
        tokens.safeTransferFrom(_eoa, address(this), _amount);
        emit UserTokenDeposited(
            tokenName,
            _tokenAddr,
            _mbWallet,
            _eoa,
            _amount
        );
    }

    /// @notice deposits value into MB Wallet as user uses fiat to get DUSD tokens on Laos Chain
    /// @param _mbWallet = MB wallet Address
    /// @param _amount = amount in USD value
    function depositFiat(address _mbWallet, uint256 _amount) external pausable {
        user[_mbWallet].dusdBalance += _amount;
        emit UserFiatDeposited(_mbWallet, _amount);
    }

    /// @notice allow users to withdraw or swap from DUSD to stablecoins based on the amount in USD that users deposited into MB Master Contract
    /// @dev only MB wallet users can use withdraw() function, otherwise revert transaction
    /// @param _eoa = user's Externally Owned Wallet, needs to be whitelisted in balances[msg.sender].Eoa otherwise revert
    /// @param _tokenAddr = token Address, would need some form of authentication to verify address belongs to official stablecoin
    /// @param _amount ? = amount in USD value, meaning every swap requires an oracle or subgraph to receive price feed to convert amount from USD
    function withdrawTokens(
        address _mbWallet,
        address _eoa,
        address _tokenAddr,
        uint256 _amount
    ) external isMBUser pausable {
        uint256 currentTokenBalance = user[_mbWallet]
            .tokenBalance[_tokenAddr]
            .balance;
        if (currentTokenBalance < _amount) {
            revert InsufficientFunds({
                request: _amount,
                balance: currentTokenBalance
            });
        }
        if (user[_mbWallet].eoa != _eoa) {
            revert IncorrectEOA();
        }
        user[_mbWallet].tokenBalance[_tokenAddr].balance -= _amount;
        IERC20MetadataUpgradeable tokens = IERC20MetadataUpgradeable(
            _tokenAddr
        );
        string memory tokenName = tokens.name();
        tokens.safeTransfer(_eoa, _amount);
        emit UserTokenWithdrawn(
            tokenName,
            _tokenAddr,
            _mbWallet,
            _eoa,
            _amount
        );
    }

    // =============================================
    //          EXTERNAL VIEW FUNCTIONS
    // =============================================

    /// @notice displays user balance on mobile app, Note: user will not see their MBWallet address, just balance and EOAWallet
    /// @dev only MB wallet users can use showUserTokenBalance() function
    /// @param _mbWallet = MB wallet address
    /// @return TokenBalance[] = Struct of token balance
    function showUserTokenBalance(
        address _mbWallet
    ) external view isMBUser returns (TokenBalance[] memory) {
        address[] storage allTokens = user[_mbWallet].tokens;
        TokenBalance[] memory balances = new TokenBalance[](allTokens.length);
        for (uint256 i = 0; i < allTokens.length; i++) {
            TokenBalance memory balance = user[_mbWallet].tokenBalance[
                allTokens[i]
            ];
            balances[i] = balance;
        }
        return balances;
    }

    /// @notice displays user balance on mobile app, Note: user will not see their MBWallet address, just balance and EOAWallet
    /// @dev only MB wallet users can use showUserDusdBalance() function
    /// @param _mbWallet = MB wallet address
    /// @return uint256 = Balance of DUSD in value
    function showUserDusdBalance(
        address _mbWallet
    ) external view isMBUser returns (uint256) {
        return user[_mbWallet].dusdBalance;
    }

    /// @notice display user current registered Externally Owned Account
    /// @dev only MB wallet users can use showUserEoa() function
    /// @param _mbWallet = MB wallet address
    /// @return address = user's current EOA address
    function showUserEoa(
        address _mbWallet
    ) external view isMBUser returns (address) {
        return user[_mbWallet].eoa;
    }

    /// @notice checks if user is already a MB user by verifying if balances[msg.sender].isMBUser is true or false
    /// @param _mbWallet = MB wallet address
    function checkExistingUser(address _mbWallet) external view returns (bool) {
        return user[_mbWallet].isMBUser;
    }

    // =============================================
    //               INTERNAL FUNCTIONS
    // =============================================

    function _checkExistingUser(
        address _mbWallet
    ) internal view returns (bool) {
        return user[_mbWallet].isMBUser;
    }

    function _withdraw(address _tokenAddr, uint256 _amount) private {
        IERC20MetadataUpgradeable tokens = IERC20MetadataUpgradeable(
            _tokenAddr
        );
        tokens.safeTransfer(owner(), _amount);
    }

    function _withdrawEth(uint256 _amount) private {
        if (address(this).balance < _amount) {
            revert InsufficientFunds({
                request: _amount,
                balance: address(this).balance
            });
        }
        (bool sent, ) = owner().call{value: _amount}("");
        require(sent, "withdraw failed");
    }
}
