// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Storage {
    uint256 public a;
    uint256 public b;
    uint256 public c;
 
    function foo() public {
        a = 1;
        b = 2;
        c = 123;
    }
}