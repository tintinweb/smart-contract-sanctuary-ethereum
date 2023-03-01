/**
 *Submitted for verification at Etherscan.io on 2023-03-01
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Counter {

    uint256 public currCount = 0;
    bool public paused; // false
    address owner; // 0x0000000

    function getOwner() public view returns(address) {
        return owner;
    }

    constructor() {
        paused = true;
        owner = msg.sender;
    }

    function unpause() external {
        require(msg.sender == owner, "you are not owner");
        paused = false;
    }

    function increment() external {
        require(!paused, "smart contract is paused");        
        currCount++;        
    }

    
}