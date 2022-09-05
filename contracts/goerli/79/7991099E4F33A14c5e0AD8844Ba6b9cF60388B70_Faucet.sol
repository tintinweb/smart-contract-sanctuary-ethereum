/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Faucet{
    uint256 immutable min = 100_000_000_000_000_000; // 0.1 eth
    address owner;

    receive() external payable {}

    constructor() {
        owner = msg.sender;
    }

    function withdraw(uint256 amount) external onlyOwner{
        require(amount < min, "Amount is too high.");

        payable(msg.sender).transfer(amount);
    }

    modifier onlyOwner {
       require(msg.sender == owner, "Only owner are allowed.");
       _;
    }
}