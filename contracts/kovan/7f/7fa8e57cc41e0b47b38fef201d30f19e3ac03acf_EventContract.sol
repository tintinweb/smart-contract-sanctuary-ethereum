/**
 *Submitted for verification at Etherscan.io on 2022-07-01
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

contract EventContract {
    
    uint public voteNumber = 1;
    uint public side = 0;
    uint public num = 0;
    uint public timestamp = 0;
    
    event _setNumber(address send, uint x, uint voteNumber);
    
    constructor() {
        
    }

    function placeOrder (uint _side, uint _num, uint _timestamp) public {
        side = _side;
        num = _num;
        timestamp = _timestamp;
    }
    
    function setNumber(uint x) public {
        voteNumber += x;
        emit _setNumber(address(msg.sender), x, voteNumber);
    }
    
    function getNumber() public view returns(uint retVal) {
        return voteNumber;
    }
}