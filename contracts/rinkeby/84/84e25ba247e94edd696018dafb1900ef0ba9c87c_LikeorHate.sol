/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
// 20220922
pragma solidity ^0.8.0;

contract LikeorHate {
    uint a;
    uint b;
    uint c;
    uint d;

    function LikeP() public returns(uint) {
        a = a + 1;
        return a;
    }

    function CheckLikeP() public view returns(uint) {
        return a;
    }

    function HateP() public returns(uint) {
        b = b + 1;
        return b;
    }

    function CheckHateP() public view returns(uint) {
        return b;
    }

    function LikeH() public returns(uint) {
        c = c + 1;
        return c;
    }

    function CheckLikeH() public view returns(uint) {
        return c;
    }

    function HateH() public returns(uint) {
        d = d + 1;
        return d;
    }

    function CheckHateH() public view returns(uint) {
        return d;
    }
}