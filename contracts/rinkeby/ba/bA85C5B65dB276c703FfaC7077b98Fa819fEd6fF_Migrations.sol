// SPDX-License-Identifier: MIT
// solhint-disable-next-line
pragma solidity >=0.4.22 <0.9.0;

contract Migrations {
  address public owner = msg.sender;
  uint public lastCompletedMigration;

  modifier restricted() {
    require(
      msg.sender == owner,
      "You are not the owner"
    );
    _;
  }

  function setCompleted(uint completed) public restricted {
    lastCompletedMigration = completed;
  }
}