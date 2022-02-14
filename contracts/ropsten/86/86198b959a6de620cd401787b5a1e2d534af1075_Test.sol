/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;


contract Test {
    event Log(uint,string,bool);

    function log() external {
        emit Log(0x61626364, "hello", true);
    }
}