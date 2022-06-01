/**
 *Submitted for verification at Etherscan.io on 2022-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SetAndGetNumber {
    uint256 public number;
    
    function set(uint256 _number) public {
        number = _number;
    }

}