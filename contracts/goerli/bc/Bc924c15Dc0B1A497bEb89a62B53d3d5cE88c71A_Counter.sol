/**
 *Submitted for verification at Etherscan.io on 2023-03-05
*/

// SPOX-License-Identifier: MIT
pragma solidity 0.8.4;
contract Counter {
   uint public count;
    // Function te get the current count
    function get() public view returns (uint) {
        return count;
    }
   //Function to increment count by :
   function inc() public {
        count += 1;
   }

   //Function to decrement count by 2
   function dec() public {
       //This function will fail If count = 0
        count -= 1;
    }
}