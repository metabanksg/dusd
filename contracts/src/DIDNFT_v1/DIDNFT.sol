// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721.sol";

contract DIDNFT is ERC721 {
    uint256 private tokenIdCounter;
    mapping(uint256 => string) private tokenIdsToNumbers;
    mapping(uint256 => address) private tokenIdsToAddresses;

    mapping(string => address) private numberToAddress;
    mapping(address => string) private addressToNumber;

    mapping(string => bool) private numberExists;
    mapping(address => bool) private addressExists;

    constructor() ERC721("DIDNFT", "NFT") {}

    function mint(address to, string memory number) public returns (uint256) {
        require(!numberExists[number], "Number already exists");
        require(!addressExists[to], "Address already exists");
        tokenIdCounter++;
        _safeMint(to, tokenIdCounter);

        tokenIdsToNumbers[tokenIdCounter] = number;
        tokenIdsToAddresses[tokenIdCounter] = to;

        numberToAddress[number] = to;
        addressToNumber[to] = number;

        numberExists[number] = true;
        addressExists[to] = true;
        return tokenIdCounter;
    }

    function getNumber(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        return tokenIdsToNumbers[tokenId];
    }

    function getAddress(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "Token does not exist");
        return tokenIdsToAddresses[tokenId];
    }

    function getAddressByNumber(string memory number) public view returns (address) {
        require(numberExists[number], "Number does not exist");
        return numberToAddress[number];
    }

    function getNumberByAddress(address addr) public view returns (string memory) {
        require(addr != address(0), "Invalid address");
        return addressToNumber[addr];
    }
}
