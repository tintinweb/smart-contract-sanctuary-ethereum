/**
 *Submitted for verification at Etherscan.io on 2023-03-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AgentImplementation {
    uint256 private _foo;

    function initialize() external {
        require(_foo == 0);
        _foo = 1;
    }

    function readFoo() external view returns (uint256) {
        return _foo;
    }

    function writeFoo() external {
        _foo++;
    }
}