/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract D {
    function exp2(uint a) public view returns(uint) {
        return a * a;
    }

    function exp3(uint a) public view returns(uint) {
        return a * a * a;
    }

    function remainder(uint a, uint b) public view returns(uint, uint) {
        return (a / b, a % b);
    }
}