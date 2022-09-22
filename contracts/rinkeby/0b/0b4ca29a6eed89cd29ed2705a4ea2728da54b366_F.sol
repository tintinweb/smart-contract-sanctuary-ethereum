/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

// SPDX-License-Identifier: GPL-3.0
// 20220922

pragma solidity >=0.7.0 <0.8.2;

contract F {
    function A(uint a) public view returns (uint) {
        return a**2;
    }
    function B(uint a) public view returns (uint) {
        return a**3;
    }
    function C(uint a, uint b) public view returns (uint, uint) {
        return (a/b, a%b);
    }
}