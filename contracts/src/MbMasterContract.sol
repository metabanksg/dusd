// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

/**
 * @title Upgradable MB Master Contract for Ethereum
 * @author MetaBank SG
 * @notice This smart contract is used to handle MB liquidity pool and user balances
 * @custom:experimental version 1.0.0
 */

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

contract MbMasterContract is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

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

    /// @notice balances address refers to user's MB Wallet
    mapping(address => User) private balances;
    bool public isPaused;

    modifier Pausable() {
        require(isPaused == false, "paused");
        _;
    }

    modifier isMBUser() {
        require(balances[msg.sender].isMBUser == true, "Not MB User");
        _;
    }

    /// @notice empty receive function to allow smart contract to collect Native Token(Ethereum)
    receive() external payable {}

    /// @notice initializer can only be executed once upon deployment, will not be re-initiated after contract upgrades.
    /// @dev initializes ownership to address deployer
    function initialize() external initializer {
        __Ownable_init();
    }

    /// @notice register's new user by storing MB Wallet address into smart contract and enabling "isMBUser" to true
    /// @dev only owner can access registerNewUser() function
    /// @param _mbWalletAddress = user's new MB wallet address
    function registerNewUser(address _mbWalletAddress) external onlyOwner {
        require(balances[_mbWalletAddress].isMBUser == false, "Already user");
        balances[_mbWalletAddress].isMBUser = true;
        balances[_mbWalletAddress].MBWallet = _mbWalletAddress;
    }

    /// @notice stops all transactions from taking place, which includes withdraw and deposit due to security issues
    /// @dev only owner can pause smart contract
    function pause() external onlyOwner {
        require(isPaused == false, "already paused");
        isPaused = true;
    }

    /// @notice resumes all transactions as risks have been averted
    /// @dev only owner can unpause smart contract
    function unpause() external onlyOwner {
        require(isPaused == true, "already unpaused");
        isPaused = false;
    }

    /// @notice allows for owner to withdraw tokens from this smart contract
    /// @param _tokenAddr = token address used to attach to IERC20 Interface
    /// @param _amount = amount of tokens to withdraw
    function AdminExtract(
        address _tokenAddr,
        uint256 _amount
    ) external onlyOwner {
        _withdraw(_tokenAddr, _amount);
    }

    /// @notice allows for owner to withdraw ether from this smart contract
    /// @param _amount = amount of ether to withdraw
    function AdminWithdrawEth(uint256 _amount) external onlyOwner {
        _withdrawEth(_amount);
    }

    /// @notice allow for users to re-register their Externally Owned Wallet, would require a lock down period for security purposes
    /// @dev only MB wallet users can use showUserBalance() function
    /// @param _newEoa new Externally Owned Wallet, must not be the same as the current EOA address, otherwise revert transaction
    function changeEoa(address _newEoa) external isMBUser {
        balances[msg.sender].Eoa = _newEoa;
    }

    function depositWithEoa(
        address _mbWallet,
        uint256 _amount
    ) external isMBUser {
        balances[_mbWallet].Balance += _amount;
    }

    function withdraw(uint256 _amount) external isMBUser {
        balances[msg.sender].Balance -= _amount;
    }

    function showUserBalance()
        external
        view
        isMBUser
        returns (address, uint256, address)
    {
        User memory user = balances[msg.sender];
        return (user.MBWallet, user.Balance, user.Eoa);
    }

    function checkAlreadyUser() external view returns (bool) {
        return balances[msg.sender].isMBUser;
    }

    function _withdraw(address _tokenAddr, uint256 _amount) private {
        IERC20Upgradeable tokens = IERC20Upgradeable(_tokenAddr);
        tokens.transfer(owner(), _amount);
    }

    function _withdrawEth(uint256 _amount) private {
        (bool sent, ) = owner().call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }
}
