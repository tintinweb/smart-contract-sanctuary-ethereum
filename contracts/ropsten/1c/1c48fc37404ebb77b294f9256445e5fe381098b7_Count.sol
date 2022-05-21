/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

pragma solidity ^0.8.3;

contract Count
 {

   uint public count=0;
   uint public multiplier=2;

   event mine(string, uint);

   function add(uint x, uint y) public returns(uint)
   {
       count= x+y;
       return count;

   }

   function sub() public returns(uint)
   {
       count-=1;
       emit mine("the adition is", count+1);
       return count;
       
   }

   function multiple() public returns(uint)
   {
       count=multiplier*count;
       return count;
   }
   function reset() public returns(uint)
   {
       count=0;
       return count;
   }

   
 }