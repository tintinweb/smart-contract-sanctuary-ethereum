/**
 *Submitted for verification at Etherscan.io on 2023-03-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract Basic {
    uint256 public value;

    constructor(uint256 _value) {
        value = _value;
    }

    function foo() external pure returns (uint256) {
        return 100;
    }

    function foo2(uint256 a, bool b) external pure returns (uint256) {
        require(a != 10, "a cant be 10");
        require(b, "b must be true");
        return 101;
    }

    function deposit() external payable returns (uint256) {
        return 102;
    }
}