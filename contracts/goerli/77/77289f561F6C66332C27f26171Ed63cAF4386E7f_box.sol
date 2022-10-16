// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract box {
    uint public val;
    constructor() {
    }
    function setVal(uint _val) external {
        val = _val;
    }
}