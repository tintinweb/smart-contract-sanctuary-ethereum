/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Greeter {
    uint a;

    function add() public returns (uint) {
        a = a + 10;
        return a;
    }
}