/**
 *Submitted for verification at Etherscan.io on 2022-12-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract ICallee {
    uint public x;
    uint public value;

    function setX(uint _x) public returns (uint) {
    }

    function setXandSendEther(uint _x) public payable returns (uint, uint) {
    }
}

contract Caller {
    function setX(ICallee _callee, uint _x) public {
        uint x = _callee.setX(_x);
    }

    function setXFromAddress(address _addr, uint _x) public {
        ICallee callee = ICallee(_addr);
        callee.setX(_x);
    }

    function setXandSendEther(ICallee _callee, uint _x) public payable {
        (uint x, uint value) = _callee.setXandSendEther{value: msg.value}(_x);
    }
}