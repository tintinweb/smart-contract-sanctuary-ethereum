/**
 *Submitted for verification at Etherscan.io on 2022-12-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract V3 {
   uint public number;

   function initialValue(uint _num) external {
       number=_num;
   }

   function increase() external {
       number += 1;
   }
      function decrease() external {
       number -= 1;
   }
    function increaseby5() external{
        number +=5;
    }
}