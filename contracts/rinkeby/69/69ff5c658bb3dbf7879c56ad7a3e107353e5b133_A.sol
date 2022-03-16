/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.1 <0.9.0;

contract A {
    uint256 public variable;
    
    function set() public {
        variable = (variable++);
    }
}