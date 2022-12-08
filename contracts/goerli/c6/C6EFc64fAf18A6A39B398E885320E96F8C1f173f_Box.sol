// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/*
proxy --> implementation
  ^
  |
  |
proxy admin
*/

contract Box {
    uint public val;

    // for upgradeable contracts state variables inside implementation are never used
    // constructor(uint _val) {
    //     val = _val;
    // }

    function initialize(uint _val) external {
        val = _val;
    }
}