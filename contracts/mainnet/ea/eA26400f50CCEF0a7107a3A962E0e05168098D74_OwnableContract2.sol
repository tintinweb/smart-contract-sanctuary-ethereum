/**
 *Submitted for verification at Etherscan.io on 2023-06-03
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

contract OwnableContract2 {
    address public owner;
    constructor(){
        owner = msg.sender;
    }
}