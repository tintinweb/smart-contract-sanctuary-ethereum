pragma solidity >=0.7.3;

// Defines a contract named HelloWorld.

contract HelloWorld {
	// Emitted when update function is called
	// Smart contract events are a way for your contract to communicate that something happened 
	// on the blockchain to your app front-end, which can be 'listening' for certain events and 
	// take action when they happen.
	event UpdatedMessages(string oldStr, string newStr);

	// Declares a state variable 'message' of type 'string'. 
	string public message;

	constructor(string memory initMessage) {
		message = initMessage;
	}

	function update(string memory newMessage) public {
		string memory oldMessage = message;
		message = newMessage;

		emit UpdatedMessages(oldMessage, newMessage);
	}
}