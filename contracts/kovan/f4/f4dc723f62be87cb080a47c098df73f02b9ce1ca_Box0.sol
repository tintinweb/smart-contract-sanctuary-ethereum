/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/*
proxy --> implementation
  ^
  |
  |
proxy admin
*/

contract Box0 {
    uint public val;

    // constructor(uint _val) {
    //     val = _val;
    // }

    function initialize(uint _val) external {
        val = _val;
    }
}