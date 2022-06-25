/**
 *Submitted for verification at Etherscan.io on 2022-06-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract tesn{
    uint message = 100;

    function reading() view public returns(uint){
        return message;
    }

    function writing(uint _num1, uint _num2) public {
        message = _num1 + _num2;
    }
}