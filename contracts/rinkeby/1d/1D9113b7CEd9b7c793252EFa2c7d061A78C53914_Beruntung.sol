/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

contract Beruntung {
    function attack(address payable _address) public {
         selfdestruct(_address);
    }
 }