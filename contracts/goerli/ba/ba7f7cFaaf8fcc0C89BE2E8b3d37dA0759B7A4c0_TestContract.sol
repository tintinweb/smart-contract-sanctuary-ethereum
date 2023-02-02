/**
 *Submitted for verification at Etherscan.io on 2023-02-02
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract TestContract {
    constructor() {
        b = hex"12345678901234567890123456789012";
    }

    event Event(uint256 indexed a, bytes32 b);
    event Event2(uint256 indexed a, bytes32 b);

    function foo(uint256 a) public {
        emit Event(a, b);
    }

    bytes32 b;
}