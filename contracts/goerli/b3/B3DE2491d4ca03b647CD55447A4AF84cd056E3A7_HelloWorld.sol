// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract HelloWorld {
	// Storage variable for the user message.
	// Stored on the chain. Only my contract can access it, but it's not hidden on the blockchain.
	string private message;
	address public owner;

	event MessageChanged(string newMessage);

	modifier onlyOwner {
		require(msg.sender == owner, "Caller must be the owner");
		_;
	}

	// Run only once in creation of the contract
	constructor(string memory _initMessage) {
		message = _initMessage;
		owner = msg.sender;
	}

	function setMessage(string memory _newMessage) public onlyOwner {
		require(bytes(_newMessage).length > 0, "Empty string not allowed");

		message = _newMessage;
		emit MessageChanged(_newMessage);
	}

	function getMessage() public view returns (string memory) {
		return message;
	}
}