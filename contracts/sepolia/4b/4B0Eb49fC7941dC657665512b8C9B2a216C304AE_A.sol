/**
 *Submitted for verification at Etherscan.io on 2023-07-13
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

contract A {
    uint256 private jimbo = 9;  

    function changeJimbo(uint256 _x) external payable {
        jimbo = _x;
    }
}