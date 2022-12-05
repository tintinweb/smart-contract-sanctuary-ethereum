/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract SAMPLECONTRACT {
    uint a;

    function A(uint _a) public view returns(uint) {
        return a+_a;
    }

    function B(uint _b) public returns(uint) {
        a = a+_b;
        return a;
    }
}