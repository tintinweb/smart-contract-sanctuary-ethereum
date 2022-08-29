/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Calculate {
    uint256 num1;
    uint256 num2;

    function enterNumbers(uint256 _num1, uint256 _num2) public {
        num1 = _num1;
        num2 = _num2;
    }

    function getSum() public view returns (uint256) {
        return num1 + num2;
    }
}