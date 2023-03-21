/**
 *Submitted for verification at Etherscan.io on 2023-03-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AgentImplementation {
    uint256 private foo;

    function readFoo() external view returns (uint256) {
        return foo;
    }

    function writeFoo() external {
        foo++;
    }
}