/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract TestRevert {

    uint256 a;
    uint256 b;
    uint256 c;
    uint256 d;

    function set() public returns(bool) {
        a = 1;
        b = 2;
        c = 3;
        d = 4;
        return true;
    }

    function reset() public returns(bool) {
        a = 0;
        b = 0;
        c = 0;
        d = 0;
        return true;
    }

    function get() public view returns(uint256) {
        return a + b + c + d;
    }

}