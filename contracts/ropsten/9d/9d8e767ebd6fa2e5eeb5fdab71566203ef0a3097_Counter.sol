/**
 *Submitted for verification at Etherscan.io on 2022-04-27
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

contract Counter {
 
    uint256 private counter;
 
    function increment() public {
        counter++;
    }
 
    function read() public view returns (uint256) {
        return counter;
    }
   
}