/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

contract TToZZI {

   string count = "First Story of TToZZI"; 
   uint counts = 3;

   function my_function1() public view returns(string memory){ 
       return count;
   }

    function TTLDonation() public view returns(uint){ 
       return counts;
   }

   function Donation() public{
       counts = counts + 1;
   }

      function my_function4(string memory txt) public{
       count = string.concat(count,txt);
   }
}