// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Test {
    int a;
    int b;
    int c;
    int d;

    function set(int i, int j) public {
        a = i;
        b = j;
        c=a+b;
        d = c +1;
    }

    function get() public view returns (int) {
        return d;
    }
}