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


    // This is because for upgradable contracts 
    // The state variables inside the implementation are never used
    // No contractors for upgradable contracts
    // constructor(uint _val) {
    //     val = _val;
    // }

    function initialize(uint _val) external {
        val = _val;
    }
}