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

    // Upgradable logic/implementation contracts don't use contructors bc their state isn't used (which what is set by constructor). Instead state is stored in proxy contract (init method stores it there)
    // constructor(uint _val) {
    //     val = _val;
    // }

    function initialize(uint _val) external {
        val = _val;
    }
}