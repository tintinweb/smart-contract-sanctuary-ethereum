/**
 *Submitted for verification at Etherscan.io on 2023-03-19
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Counter {
    uint256 public count;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not allowed to modify");
        _;
    }

    function increment(uint256 _count) public onlyOwner {
        count = count + _count;
    }
}