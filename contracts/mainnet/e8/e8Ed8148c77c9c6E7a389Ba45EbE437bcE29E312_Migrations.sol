// SPDX-License-Identifier: MIT
/// @dev Migrations required by Truffle
pragma solidity ^0.8.16;

contract Migrations {
	address public owner;
	uint public last_completed_migration;

	modifier restricted() {
		if (msg.sender == owner) _;
	}

	constructor() {
		owner = msg.sender;
	}

	function setCompleted(uint completed) public restricted {
		last_completed_migration = completed;
	}
}