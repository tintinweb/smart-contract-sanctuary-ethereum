// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

contract demo {
   string public message;
   
   function set(string memory na) public {
      message = na;
   }
   
   function get() public view returns  (string memory){
      return message;
   }
}