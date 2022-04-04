/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

pragma solidity ^0.5.0;

contract Test {
   function getResult() public view returns(uint product, uint sum){
      uint a = 1; // local variable
      uint b = 2;
      product = a * b;
      sum = a + b;
   }

   function getScore() public view returns(uint product, uint sum){
      uint a = 1; // local variable
      uint b = 2;
      return(a*b, a+b);
   }
}