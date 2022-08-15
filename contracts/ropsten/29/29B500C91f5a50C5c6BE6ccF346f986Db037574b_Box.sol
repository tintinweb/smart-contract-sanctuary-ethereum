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

    // 不支持构造函数 constructor

    function initialize(uint _val) external {
        val = _val;
    }
}