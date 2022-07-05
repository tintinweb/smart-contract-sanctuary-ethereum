// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/*
proxy --> implementation
  ^
  |
  |
proxy admin
*/

contract Box {
    uint public val;

    // constructor(uint _val) {
    //     val = _val;
    // }

    function initialize(uint _val) external {
        val = _val;
    }
}