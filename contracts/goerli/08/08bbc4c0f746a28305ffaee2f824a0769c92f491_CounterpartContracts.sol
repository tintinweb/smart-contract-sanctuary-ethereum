/**
 *Submitted for verification at Etherscan.io on 2022-11-05
*/

// SPDX-License-Identifier: MIT
pragma solidity  0.8.7;

contract CounterpartContracts {
     uint public counterpart;

     function increment() public {
         counterpart += 1;
    }      
}