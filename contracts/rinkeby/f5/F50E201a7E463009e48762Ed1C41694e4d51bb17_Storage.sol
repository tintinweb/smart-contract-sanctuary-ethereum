// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Storage{
   uint256 private num;
   event SetNum(uint256 newNum,uint256 time);


   function setNum(uint256 newNum) public{
       num = newNum;
       emit SetNum(newNum,block.timestamp);
   } 


   function getNum() public view returns(uint256){
       return num;
   }
}