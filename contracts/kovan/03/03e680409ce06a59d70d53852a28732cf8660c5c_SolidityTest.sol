/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

pragma solidity ^0.5.0;

contract SolidityTest {   
   constructor() public{       
   }
   function deposit() public payable {
    uint amount = address(this).balance;
   }
}