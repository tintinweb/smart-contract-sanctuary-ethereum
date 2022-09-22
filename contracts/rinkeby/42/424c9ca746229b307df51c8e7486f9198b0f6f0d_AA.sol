/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

// SPDX-License-Identifier: GPL-3.0
// 20220922
pragma solidity 0.8.0;

contract AA {
    function square(uint a) public view returns(uint) {
        return a^2;
    }

    function trip(uint a) public view returns(uint) {
        return a^3;
    }

    function div(uint a, uint b) public view returns(uint, uint) {
        return (a/b, a%b);
    }

}