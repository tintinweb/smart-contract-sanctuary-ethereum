/**
 *Submitted for verification at Etherscan.io on 2022-10-18
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
contract BasicMaths {
    function newbasicAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c > a);
    }

    function newbasicSub(uint a, uint b) public pure returns (uint c) {
        require(a >= b);
        c = a - b;
    }
 
    function newbasicMul(uint a, uint b) public pure returns (uint c) {
        require(a >= b && b > 1);
        c = a * b;
        require(c / a == b);
    }

    function newbasicDiv(uint a, uint b) public pure returns (uint c) {
        require(a > b && b > 0);
        c = a/b;
    }
}