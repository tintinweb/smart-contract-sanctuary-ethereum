/**
 *Submitted for verification at Etherscan.io on 2022-12-15
*/

pragma solidity ^0.8.7;
contract Inheritance {
   mapping(string => uint) inheritance;
   function addHeir(string memory _name, uint _value) public {
      inheritance[_name] = _value;
   }
   function recoverInheritance(string memory _name) public view returns (uint) {
      return inheritance[_name];
   }
}