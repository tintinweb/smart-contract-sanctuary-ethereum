// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract boxv2 {
    uint public val;
    constructor() {
    }
    function incVal(uint _val) external {
        val = _val+1;
    }
}