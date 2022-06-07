/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;
contract SolidityNew {
   uint256 public num;

   function updateNum(uint256 _num) public returns(uint256){
      num = _num;
      return num;
   }

}

contract A is SolidityNew{
   uint256 public number = updateNum(30);
}