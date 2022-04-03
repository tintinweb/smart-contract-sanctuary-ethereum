/**
 *Submitted for verification at Etherscan.io on 2022-04-03
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

contract CodeLength {
    event LengthCheck(uint256 length);
    constructor() {
        emit LengthCheck(address(this).code.length);
    }

    function testLength() public {
        emit LengthCheck(address(this).code.length);
    }
}