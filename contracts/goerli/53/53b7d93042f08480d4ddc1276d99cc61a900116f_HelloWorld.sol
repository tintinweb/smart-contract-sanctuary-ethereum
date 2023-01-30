// specify the version of Solidity 
pragma solidity ^0.8.17;

contract HelloWorld {
	event UpdateMessages(string oldStr, string newStr);

	string public message;

	constructor(string memory initMessage) {
		message = initMessage;
	}

	// public function that accepts string argument and updates message storage variable
	function update(string memory newMessage) public {
		string memory oldMsg = message;
		message = newMessage;
		emit UpdateMessages(oldMsg, newMessage);
	}
}