// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract WEGT {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => bool) public whitelist;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event WhitelistUpdated(address indexed account, bool isWhitelisted);

    address public owner;

    constructor() {
        name = "WEVEGold";
        symbol = "WEGT";
        decimals = 8;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can perform this action");
        _;
    }

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], "Address is not whitelisted");
        _;
    }

    function addToWhitelist(address account) public onlyOwner {
        whitelist[account] = true;
        emit WhitelistUpdated(account, true);
    }

    function removeFromWhitelist(address account) public onlyOwner {
        whitelist[account] = false;
        emit WhitelistUpdated(account, false);
    }

    function mint(address to, uint256 value) public onlyWhitelisted {
        require(to != address(0), "Invalid address");
        totalSupply += value;
        balanceOf[to] += value;
        emit Mint(to, value);
        emit Transfer(address(0), to, value);
    }

    function burn(address to, uint256 value) public onlyWhitelisted {
        require(balanceOf[to] >= value, "Insufficient balance");
        totalSupply -= value;
        balanceOf[to] -= value;
        emit Burn(to, value);
        emit Transfer(to, address(0), value);
    }

    function transfer(address from, address to, uint256 value) public onlyWhitelisted {
        require(balanceOf[from] >= value, "Insufficient balance");
        require(to != address(0), "Invalid address");
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }
}
