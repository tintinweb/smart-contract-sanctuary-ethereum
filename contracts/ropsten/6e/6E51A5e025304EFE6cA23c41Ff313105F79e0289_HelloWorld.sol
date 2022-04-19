// Specify the version of Solidity
pragma solidity >=0.7.3;

// Define the contract that hosts the functions and state
contract HelloWorld {

	// event listener to communicate contract interactions to front end
	event UpdatedMessages(string oldStr, string newStr);

	// Create a public state variable
	string public message;

	// constructor for contract creation
	constructor(string memory initMessage) {

		// accepts a string argument and sets the value into the contract's message variable
		message = initMessage;
	}

	// public function that accepts a string and updates the message
	function update(string memory newMessage) public {
		string memory oldMsg = message;
		message = newMessage;
		emit UpdatedMessages(oldMsg, newMessage);
	}
}