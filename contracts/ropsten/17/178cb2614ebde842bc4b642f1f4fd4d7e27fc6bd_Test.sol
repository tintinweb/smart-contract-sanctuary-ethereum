/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <0.9.0;


contract Test {
    uint public a = 256;

    function getA() external view returns (uint) {
        return a;
    }
}