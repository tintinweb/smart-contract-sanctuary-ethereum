/**
 *Submitted for verification at Etherscan.io on 2022-03-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

contract Y {
    address public immutable owner;
    uint256 public currentValue;
    address public lastCaller;

    constructor () {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    function changeState (uint256 newValue) public onlyOwner {
        currentValue = newValue;
    }

    function anyCallerWilldo (uint256 newValue) public {
       currentValue = newValue;
       lastCaller = msg.sender;
    }
}