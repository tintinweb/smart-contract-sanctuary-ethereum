/**
 *Submitted for verification at Etherscan.io on 2022-08-20
*/

// SPDX-License-Identifier: None

pragma solidity >= 0.8.9;

contract HelloWorld {
	event UpdatedMessages(string oldString, string newString);

	string public message;

	constructor(string memory initMessage) {
		message = initMessage;
	}

	function update(string memory newMessage) public {
		string memory oldMsg = message;
		message = newMessage;
		emit UpdatedMessages(oldMsg, newMessage);
	}

}