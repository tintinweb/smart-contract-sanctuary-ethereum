//Specifies version of Solidity
pragma solidity >= 0.7.3;

//Defines a Hello World smart contract
//Once deployed, a contract resides at a specific address on the Ethereum blockchain
contract HelloWorld {

	//Emitted when update function is called
	//Listening for certain events and take action when they happen
	event UpdatedMessages(string oldStr, string newStr);

	//State variable. Public, so can be accessed from outside the contract
	string public message;

	//Special function that is only executed when contract created
	constructor( string memory initMessage){

		//Acceots string arg 'initMessage' and sets value to into contract's 'message' storage variable
		message = initMessage;
	}

	//Public function takes string arg and updates the 'message' storage variable
	function update(string memory newMessage) public {
		string memory oldStr = message;
		message = newMessage;
		emit UpdatedMessages(oldStr, newMessage);

	}

}