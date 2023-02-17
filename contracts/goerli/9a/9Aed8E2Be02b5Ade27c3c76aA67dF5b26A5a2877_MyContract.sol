//SPDX-License-Identifier:MIT
pragma solidity ^0.8.9;
 
contract MyContract {
 
 uint num;
 
 function increment() public {
   num += 1;
 }
 
 function decrement() public {
   num -= 1;
 }
  function getNum() public view returns(uint) {
   return num;
 }
}