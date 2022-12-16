/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract TToZZI {

   string count = "TToZZI have to go to sleep"; 
   uint counts = 3;

   function my_function1() public view returns(string memory){ 
       return count;
   }

   function my_function2() public{
       counts = counts + 1;
   }
}