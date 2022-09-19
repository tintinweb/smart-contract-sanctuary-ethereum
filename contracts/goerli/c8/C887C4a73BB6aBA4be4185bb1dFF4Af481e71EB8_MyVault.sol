// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract MyVault {
    address payable public owner;

    mapping(address => string) vaultUris;

    constructor() {
        owner = payable(msg.sender);
    }

    function updateVault(string calldata uri) public {
        vaultUris[msg.sender] = uri;
    }

    function getVault() public view returns (string memory) {
        return vaultUris[msg.sender];
    }
}