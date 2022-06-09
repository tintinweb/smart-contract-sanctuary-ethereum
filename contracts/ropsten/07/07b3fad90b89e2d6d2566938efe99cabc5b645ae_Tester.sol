/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Tester{
    uint public value = 0;

    function setValue(uint _value) public payable returns(uint){
        require(msg.value > 0, "Need to send some tokens");
        value += _value;
        return value;
    }
}