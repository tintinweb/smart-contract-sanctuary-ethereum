/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract HelloWorld {
    
    string[] public info;

    function setA(string[] memory newInfo) public {
        info = newInfo;
    }
}