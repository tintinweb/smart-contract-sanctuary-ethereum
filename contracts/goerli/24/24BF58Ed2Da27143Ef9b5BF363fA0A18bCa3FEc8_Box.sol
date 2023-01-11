// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
proxy --> implementation
  ^
  |
  |
proxy admin
*/

contract Box {
    uint public val;

    // For upgradeable contracts, the state variables inside the
    // implementation are never used
    // Remember that we can't have any constructors for upgradeable contracts
    // constructor(uint _val) {
    //     val = _val;
    // }

    function initialize(uint _val) external {
        val = _val;
    }
}