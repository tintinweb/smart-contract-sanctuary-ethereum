/**
 *Submitted for verification at Etherscan.io on 2022-07-15
*/

pragma solidity ^0.8.0;
contract SolidityTest2 {
   function getResult(uint16 a, uint16 b) public pure returns(uint16){
      uint16 result = a + b;
      return result;
   }
   function getResult2(uint16 a, uint16 b) public pure returns(uint16){
      uint16 result = a - b;
      return result;
   }   
}