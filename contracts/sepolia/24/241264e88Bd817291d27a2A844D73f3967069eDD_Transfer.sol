// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
//import "hardhat/console.sol";

contract Transfer {
    address owner;

    constructor() {
        owner = msg.sender;
    }

    function balanceOf(address ownerAddress) public view returns (uint256) {
        return ownerAddress.balance;
    }

    function transfer(address to, uint amount) external payable {
        payable(to).transfer(amount);
    }
}