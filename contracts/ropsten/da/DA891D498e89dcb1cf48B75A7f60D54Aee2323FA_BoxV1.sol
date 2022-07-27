// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract BoxV1 {
    uint public val;

    function initialize(uint _val) external {
        val = _val;
    }

    function getVal() public view returns (uint) {
        return val;
    }
}