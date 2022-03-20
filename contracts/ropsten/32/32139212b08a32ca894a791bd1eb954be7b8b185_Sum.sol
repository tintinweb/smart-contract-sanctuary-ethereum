/**
 *Submitted for verification at Etherscan.io on 2022-03-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract Sum {
    uint num1;
    uint num2;

    function setNum1(uint _n1) public {
        num1 = _n1;
    }

    function setNum2(uint _n2) public {
        num2 = _n2;
    }

    function sum() public view returns (uint) {
        return (num1 + num2);
    }
}