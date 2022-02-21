/**
 *Submitted for verification at Etherscan.io on 2022-02-21
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Migrations {
  uint public age;
  function setCompleted(uint _age) public  {
    age = _age;
  }
  function getCompleted() public view returns(uint) {
    return age;
  }
}