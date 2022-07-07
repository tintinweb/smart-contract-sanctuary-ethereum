/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity < 0.21.4 ;
contract person 
{
 string name;
 string gender;
 uint age;
  

 function setName(string memory newName) public
 {
 name=newName;

 }
 function getName()public view returns(string memory)
 {
 return name;
 }
 function setGender(string memory newGender)public
 {
gender=newGender;
 }
 function getGender() public view returns(string memory)
 {
     return gender;
 }
 function setAge(uint newAge) public
 {
 age=newAge;

 }

 function getAge()public view returns(uint)
 {
 return age;
 }
}