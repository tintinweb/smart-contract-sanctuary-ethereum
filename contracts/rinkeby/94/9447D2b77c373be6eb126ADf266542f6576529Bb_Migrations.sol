// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Migrations {
    address public owner = msg.sender;
    uint256 public last_completed_migration;

    function setCompleted(uint256 completed) public {
        last_completed_migration = completed;
    }
}