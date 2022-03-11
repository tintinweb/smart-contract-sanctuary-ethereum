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

    // constructor(uint _val) {
    //     val = _val;
    // }

    function initializeINC(uint _val) external {
        val = _val;
    }

    function initializeDEC(uint _val) external {
        val = val - _val;
    }
}