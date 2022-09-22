/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

// SPDX-License-Identifier: GPL-3.0
// 20220922
pragma solidity 0.8.0;

contract F {
    function mulmul(int a) public view returns(int) {
        return a**2;
    }
    function mulmulmul(uint a) public view returns(uint) {
        return a*a**2;
    }
    function div(uint a, uint b) public view returns(uint, uint) {
        return (a/b, a%b);
    }
}