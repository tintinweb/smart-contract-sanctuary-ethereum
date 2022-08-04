/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Migrations {
  address public owner = msg.sender;
  uint public last_completed_migration;


  function getNumber() public pure returns(uint){
    return 10;
  }
  function setCompleted(uint completed) public {
    last_completed_migration = completed;
  }
}