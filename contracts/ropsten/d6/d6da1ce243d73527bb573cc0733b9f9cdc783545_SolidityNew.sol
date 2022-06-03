/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;
contract SolidityNew {
   constructor(){
      owner = msg.sender;
   }
   address public owner;
   uint public exampleVar;


   modifier onlyOwner(){
      require(owner == msg.sender,"only owner may call this fucntion");
      _;
   }
   function updateVar(uint _exampleVar) public onlyOwner{
      exampleVar = _exampleVar;
   }
}