/**
 *Submitted for verification at Etherscan.io on 2022-05-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract test {
    function abc() view public returns(address) {
        return msg.sender; 
    }
}