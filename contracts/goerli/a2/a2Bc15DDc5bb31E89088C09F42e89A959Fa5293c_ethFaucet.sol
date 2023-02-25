/**
 *Submitted for verification at Etherscan.io on 2023-02-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ethFaucet {

    address public owner;
    mapping (address => uint) lastTimestamp;
    uint constant DELAY = 1 days;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "You are not an owner!");
        _;

    }

    function addFunds() external payable onlyOwner {
        
    }

    function drip(address payable _to) external {
        require(block.timestamp - lastTimestamp[_to] - DELAY >= 0, "Too early!");
        _to.transfer(0.1 ether);
        lastTimestamp[_to] = block.timestamp;

    }


}