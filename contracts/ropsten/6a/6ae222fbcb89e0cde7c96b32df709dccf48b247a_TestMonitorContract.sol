/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract TestMonitorContract {
    function testNoError() external {

    }

    function testError() external {
        revert ("testError - failed");
    }
}