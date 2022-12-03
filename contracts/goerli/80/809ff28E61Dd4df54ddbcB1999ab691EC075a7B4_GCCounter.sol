/**
 *Submitted for verification at Etherscan.io on 2022-12-03
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

contract GCCounter {

    uint8 private count;
    address private owner;

    constructor(){
        owner = msg.sender;
    }

    function increment() external {
        count++;
    }

    function resetCount() external {
        require(msg.sender == owner, "Not authorized");
        count = 0;
    }

    function setCountAt(uint8 _newCount) external {
        require(msg.sender == owner, "Not authorized");
        count = _newCount;
    }

    function getCount() external view returns (uint8){
        return count;
    }
}