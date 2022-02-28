/**
 *Submitted for verification at Etherscan.io on 2022-02-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract CallerTest {
    function setX(CalleeTest _callee, uint _x) public {
        uint x = _callee.setX(_x);
    }

    function setXFromAddress(address _addr, uint _x) public {
        CalleeTest callee = CalleeTest(_addr);
        callee.setX(_x);
    }

    function setXandSendEther(CalleeTest _callee, uint _x) public payable {
        (uint x, uint value) = _callee.setXandSendEther{value: msg.value}(_x);
    }
}


contract CalleeTest {

    function setX(uint _x) public returns (uint) {}

    function setXandSendEther(uint _x) public payable returns (uint, uint) {}
}