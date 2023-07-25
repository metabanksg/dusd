// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.4.25;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function allowance(address owner, address spender) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        address owner = msg.sender;
        approve(spender, allowance(owner, spender) + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = allowance(msg.sender, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        approve(spender, currentAllowance - subtractedValue);
        return true;
    }
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title ERC20Detailed token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 * Example inherits from basic ERC20 implementation but includes decimals field.
 */
contract ERC20Detailed is ERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string name, string symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @return the name of the token.
     */
    function name() public view returns (string) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string) {
        return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

/** 
 * @title DUSD smart contract for Fisco BCOS 
 * @author MetaBank SG
 * @notice This is the official smart contract for DUSD ERC20 Tokens on Fisco due to solidity version difference
 * @dev use this to deploy on Fisco BCOS because it uses solidity v0.6.10 which is supported
 * @dev experimental version 1.1.0 not officially audited and should be used with caution
 */

contract DUSDFiscoCompatibleFlatten is ERC20, ERC20Detailed, Ownable, Pausable {
    mapping(address => bool) public blacklist;
 
    /// @notice decimals have been changed to 6 to align with stablecoin standards
    /// @param _initialSupply to provide an initial suppply for DUSD
     constructor(uint256 _initialSupply) ERC20Detailed("DUSD", "DUSD", 6) public {
        _mint(msg.sender, _initialSupply);
    }

    /// @notice only owner allowed to mint tokens
    /// @param _to is the reciever of the newly minted tokens
    /// @param _amount is the amount of newly minted tokens
    function mint(address _to, uint256 _amount) external onlyOwner whenNotPaused {
        _mint(_to, _amount);
    }

    /// @notice only owner allowed to burn tokens
    /// @param _from is the address owner whose tokens are being burned
    /// @param _amount is the amount of tokens being burned
    function burn(address _from, uint256 _amount) external onlyOwner whenNotPaused {
        _burn(_from, _amount);
    }

    /// @notice allows the contract owner to pause the contract, triggers a paused state
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    /// @notice allows the contract owner to unpause the contract, returns to normal state
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }

    /// @notice allows the contract owner to add an address to the blacklist
    function addToBlacklist(address _address) external onlyOwner {
        blacklist[_address] = true;
    }

    /// @notice allows the contract owner to remove an address from the blacklist
    function removeFromBlacklist(address _address) external onlyOwner {
        blacklist[_address] = false;
    }

    /// @notice prevents blacklisted addresses from transferring tokens
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(!blacklist[msg.sender], "Sender address is blacklisted");
        require(!blacklist[_to], "Recipient address is blacklisted");
        return super.transfer(_to, _value);
    }

    /// @notice prevents blacklisted addresses from transferring tokens
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(!blacklist[_from], "Sender address is blacklisted");
        require(!blacklist[_to], "Recipient address is blacklisted");
        return super.transferFrom(_from, _to, _value);
    }
}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }
}