// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Test {
    int a;
    int b;
    int c;

    function set(int i, int j) public {
        a = i;
        b = j;
        c=a+b;
    }

    function get() public view returns (int) {
        return c;
    }
}