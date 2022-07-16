/**
 *Submitted for verification at Etherscan.io on 2022-07-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestTenderly {
    function testNoError() external {}

    function testErrot() external {
        revert("Fail");
    }
}