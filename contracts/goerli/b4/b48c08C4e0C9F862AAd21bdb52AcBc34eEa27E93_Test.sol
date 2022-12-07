/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

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
        d = c +3;
    }

    function get() public view returns (int) {
        return d;
    }
}