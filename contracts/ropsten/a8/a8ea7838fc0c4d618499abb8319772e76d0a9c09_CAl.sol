/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

// SPDX-Licence-Identifier: GPL-3.0
// 20220922

pragma solidity 0.8.0;

contract CAl {

    function aAdd(int p, int q) public pure returns(int) {
        return p+q;
    }

    function bSub(int p, int q) public pure returns(int) {
        return p-q;
    }

    function cMul(int p, int q) public pure returns(int) {
        return p*q;
    }

    function dDiv(int p, int q) public pure returns(int,int) {
        return (p/q, p%q);
    }
}