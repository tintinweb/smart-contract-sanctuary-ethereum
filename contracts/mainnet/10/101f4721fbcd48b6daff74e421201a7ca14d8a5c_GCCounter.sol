/**
 *Submitted for verification at Etherscan.io on 2022-12-04
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

contract GCCounter {

    uint8 private count;
    address private owner;

    constructor(address _owner){
        owner = _owner;
    }

    function increment(uint8 _amount) external {
        count+= _amount;
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