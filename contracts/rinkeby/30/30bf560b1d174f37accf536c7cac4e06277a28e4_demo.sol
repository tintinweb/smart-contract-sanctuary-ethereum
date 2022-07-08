/**
 *Submitted for verification at Etherscan.io on 2022-07-08
*/

// SPDX-License-Identifier: MIT


pragma solidity 0.8.15;


contract demo {

address public owner;


constructor () {

    owner = msg.sender;
}

   function set() public pure  returns (uint) {

       return 50;
   }





}