/**
 *Submitted for verification at Etherscan.io on 2022-11-03
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
contract arithmatic
{
   uint FirstNum;
   uint SecondNum;

   function setFirstNum(uint x) public
   {
       FirstNum = x;
   }
   function setSecondNum(uint y) public
   {
       SecondNum = y;
   }
   function add() public view returns(uint)
   {
       return FirstNum + SecondNum;
   }
   function sub() public view returns(uint)
   {
       return FirstNum - SecondNum;
   }
   function mul() public view returns(uint)
   {
       return FirstNum * SecondNum;
   }
    function div() public view returns(uint)
    {
         return FirstNum / SecondNum;
    }
    function mod() public view returns(uint)
    {
         return FirstNum % SecondNum;
    }
    
 }