/**
 *Submitted for verification at Etherscan.io on 2022-07-14
*/

pragma solidity ^0.5.0;
contract SolidityTest {
   constructor() public{
   }
   function getResult(int16 a, int16 b) public pure returns(int16){
      int16 result = a + b;
      return result;
   }
}