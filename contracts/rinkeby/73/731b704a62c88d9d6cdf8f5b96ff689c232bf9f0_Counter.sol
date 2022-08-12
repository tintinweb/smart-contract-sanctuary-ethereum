/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Counter {

    uint public count = 0; 


     function increment() public returns (uint) {
             

             return ++count;
        }
  }