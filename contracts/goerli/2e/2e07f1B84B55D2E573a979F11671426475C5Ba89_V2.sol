// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract V2 {
   uint public number;

   function initialValue(uint _num) external {
       number=_num;
   }

   function increase() external {
       number += 1;
   }

   function twiceOf() external {
    number *= 2;
   }

   function decrease() external {
       number -= 1;
   }
}