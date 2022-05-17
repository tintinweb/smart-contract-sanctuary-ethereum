/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

pragma solidity ^0.5.0;
contract SolidityTest2 {
   string public name;
   
   constructor() public{
       name="我是一個智能合約";
   }

   function getResult() public view returns(uint){
      uint a = 2;
      uint b = 3;
      uint result = a + b;
      return result;
   }

   function setName(string memory _name) public
   {

       name=_name;
   }
}