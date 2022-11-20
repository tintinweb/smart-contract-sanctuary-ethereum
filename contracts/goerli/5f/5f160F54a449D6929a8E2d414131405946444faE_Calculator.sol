/**
 *Submitted for verification at Etherscan.io on 2022-11-20
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.4.0;

contract Calculator {
    function add(uint x, uint y) public pure returns (uint) {
        return x + y;
    }
    function sub(uint x, uint y) public pure returns (uint) {
        return x - y;
    }
    function times(uint x, uint y) public pure returns (uint) {
        return x * y;
    }
    function div(uint x, uint y) public pure returns (uint) {
        return x / y;
    }
}