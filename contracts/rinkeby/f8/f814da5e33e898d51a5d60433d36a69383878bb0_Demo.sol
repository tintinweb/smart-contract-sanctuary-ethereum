/**
 *Submitted for verification at Etherscan.io on 2022-03-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Demo {

    uint a = 10;

    function getA() public view returns(uint) {
        return a;
    }

    function setA(uint v) public {
        a = v;
    }
}