/**
 *Submitted for verification at Etherscan.io on 2022-09-29
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

contract GelatoTester {

    address public owner;
    uint256 globalCounter = 0;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
       require(msg.sender == owner, "TaxToken.sol::onlyOwner(), msg.sender != owner."); 
       _;
    }

    event IncrementedGlobalCounter(uint256 _timestamp);

    function increment() external onlyOwner() {
        emit IncrementedGlobalCounter(block.timestamp);
        globalCounter++;
    }
}