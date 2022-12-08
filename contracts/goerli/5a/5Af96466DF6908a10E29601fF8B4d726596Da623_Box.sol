//SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

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