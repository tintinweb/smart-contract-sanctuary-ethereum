/**
 *Submitted for verification at Etherscan.io on 2022-12-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

contract Migrations {
  address public owner;
  uint256 public last_completed_migration;

  constructor() public {
    owner = msg.sender;
  }

  function setCompleted() public  {
    require(owner == msg.sender, "only owner.");
    last_completed_migration++;
  }
}