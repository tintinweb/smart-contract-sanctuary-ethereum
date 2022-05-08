/**
 *Submitted for verification at Etherscan.io on 2022-05-08
*/

//SPDX-License-Identifier:MIT
pragma solidity >=0.7.0 <=0.9.0;

contract test02{
   string name;
   uint number;

   function setName(string memory _name) public {
       name = _name;
   }

   function getName() public view returns(string memory) {
       return name;
   }

   function setNumber(uint _number) public {
       number = _number;
   }

   function getNumber() public view returns(uint) {
       return number;
   }
}