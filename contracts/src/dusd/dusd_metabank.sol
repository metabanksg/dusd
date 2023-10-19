// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC20.sol";
import "./Pausable.sol";

contract dusd_metabank is ERC20, Ownable, Pausable {

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public numConfirmationsRequired;
    uint public signatureAmount;
    address public aggregateAccount;

    mapping(uint => mapping(address => bool)) public isConfirmed;
    mapping(address => bool) public blacklist;

    event SubmitTransaction(address indexed owner, uint indexed txIndex, address indexed to, uint value, bytes data);
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmations;
    }

    Transaction[] public transactions;

    modifier onlyMultiOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }
    modifier onlyPrimaryOwner() {
        require(msg.sender == owners[0], "Only the primary owner can remove an owner");
        _;
    }
    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }
    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }
    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    event BalanceUpdated(address indexed account, uint256 balance);
    event PriceUpdated(uint256 price);
    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);

    constructor(uint256 _initialSupply, address[] memory _owners, uint256 _numConfirmationsRequired, uint256 _signatureAmount) ERC20("DUSD", "DUSD", 6) {
        require(_owners.length > 2, "owners required");
        require(_numConfirmationsRequired > 1 && _numConfirmationsRequired <= _owners.length, "invalid number of required confirmations");
        require(_signatureAmount > 0, "Invalid signature amount required");
        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");
            isOwner[owner] = true;
            owners.push(owner);
        }
        signatureAmount = _signatureAmount;
        numConfirmationsRequired = _numConfirmationsRequired;
        _mint(msg.sender, _initialSupply);
    }

    function addOwner(address newOwner) external onlyPrimaryOwner {
        require(newOwner != address(0), "Invalid owner address");
        require(!isOwner[newOwner], "Owner already exists");

        isOwner[newOwner] = true;
        owners.push(newOwner);
    }

    function removeOwner(address ownerToRemove) external onlyPrimaryOwner {
        require(ownerToRemove != owners[0], "Primary owner cannot be removed");
        require(isOwner[ownerToRemove], "Owner does not exist");
        require(owners.length - 1 > 2, "owners required");
        require(numConfirmationsRequired <= owners.length - 1, "invalid number of required confirmations");

        isOwner[ownerToRemove] = false;

        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == ownerToRemove) {
                owners[i] = owners[owners.length - 1];
                owners.pop();
                break;
            }
        }
    }

    function setAggregateAccount(address account) public onlyPrimaryOwner {
        aggregateAccount = account;
    }

    function updateRequiredConfirmations(uint256 _newNumConfirmationsRequired) external onlyPrimaryOwner {
        require(_newNumConfirmationsRequired > 1 && _newNumConfirmationsRequired <= owners.length, "Invalid number of required confirmations");
        numConfirmationsRequired = _newNumConfirmationsRequired;
    }

    function updateSignatureAmount(uint256 _newSignatureAmount) external onlyPrimaryOwner {
        require(_newSignatureAmount > 0, "Invalid signature amount required");
        signatureAmount = _newSignatureAmount;
    }

    function submitTransaction(address _to, uint _value, bytes memory _data) public onlyMultiOwner {

        require(!blacklist[msg.sender], "Sender address is blacklisted");
        require(!blacklist[_to], "Recipient address is blacklisted");
        uint txIndex = transactions.length;
        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );
        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    function confirmTransaction(uint _txIndex) public onlyMultiOwner txExists(_txIndex) notExecuted(_txIndex) notConfirmed(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(uint _txIndex) public onlyMultiOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        if (transaction.value >= signatureAmount) {
            require(transaction.numConfirmations >= numConfirmationsRequired, "cannot execute tx");
        }
        transaction.executed = true;
        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "tx failed");
        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(uint _txIndex) public onlyMultiOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransaction(uint _txIndex) public view returns (address to, uint value, bytes memory data, bool executed, uint numConfirmations) {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }

    function mint(address _to, uint256 _amount) external onlyPrimaryOwner {
        require(_to == aggregateAccount, "Can only mint to the specified account");
        _mint(_to, _amount);
        emit Mint(_to, _amount);
        emit BalanceUpdated(_to, balanceOf(_to));
    }

    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);
        emit Burn(msg.sender, _amount);
        emit BalanceUpdated(msg.sender, balanceOf(msg.sender));
    }

    function updatePrice(uint256 _price) external onlyPrimaryOwner {
        emit PriceUpdated(_price);
    }

    function pause() onlyPrimaryOwner whenNotPaused public {
        _pause();
    }

    function unpause() onlyPrimaryOwner whenPaused public {
        _unpause();
    }

    function addToBlacklist(address _address) external onlyPrimaryOwner {
        require(!isOwner[_address], "Owner are not allowed to blacklist");
        blacklist[_address] = true;
    }

    function removeFromBlacklist(address _address) external onlyPrimaryOwner {
        blacklist[_address] = false;
    }

    function transfer(address _to, uint256 _value) whenNotPaused public override returns (bool) {
        require(!blacklist[msg.sender], "Sender address is blacklisted");
        require(!blacklist[_to], "Recipient address is blacklisted");
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) whenNotPaused override public returns (bool) {
        require(!blacklist[_from], "Sender address is blacklisted");
        require(!blacklist[_to], "Recipient address is blacklisted");
        return super.transferFrom(_from, _to, _value);
    }
}
