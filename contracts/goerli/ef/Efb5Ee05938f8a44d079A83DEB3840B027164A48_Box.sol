// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

contract Box {
    uint public val;

    // constructor(uint _val) {
    //     val = val;
    // }

    function initialize(uint _val) external {
        val = _val;
    }
}