/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

contract TestDeploy {
    uint8 public _counter;
    
    constructor() {
      _counter=42;
    }
      
    function inc() public { _counter += 1; }
}