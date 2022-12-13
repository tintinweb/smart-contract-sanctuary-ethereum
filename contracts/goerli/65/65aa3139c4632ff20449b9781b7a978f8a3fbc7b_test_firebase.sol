/**
 *Submitted for verification at Etherscan.io on 2022-12-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract test_firebase{
    uint256 public number = 1;

    function updateNumber (uint256 _number) external {
        number = _number;
    }
}