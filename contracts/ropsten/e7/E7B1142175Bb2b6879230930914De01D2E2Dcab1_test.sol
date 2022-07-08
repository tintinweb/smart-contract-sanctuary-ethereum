/**
 *Submitted for verification at Etherscan.io on 2022-07-08
*/

//SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.7;

contract test {
    
   string fName;
   uint age;

    event Instructor(
       string name,
       uint age
    );

   function setInstructor(string memory _fName, uint _age) public {
       fName = _fName;
       age = _age;
       emit Instructor(_fName, _age);        // Add this
   }
   
   function getInstructor() view public returns (string memory, uint) {
       return (fName, age);
   }
   
}