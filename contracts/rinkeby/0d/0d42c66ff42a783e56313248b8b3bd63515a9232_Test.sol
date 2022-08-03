/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


contract Test {

    address a = 0x9226f7dF5E316df051F0490cE3b753c51695D0Bb;

    function test1() public view returns(address) {
        return msg.sender;
    }

     function test2() public view returns(address) {
        return a;
    }
}