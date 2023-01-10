pragma solidity >=0.7.0 <0.9.0;

contract HelloWorld {
    event UpdatedMessages(string oldStr, string newStr);

    /* Define variable greeting of the type string */
    string public message;

    /* This runs when the contract is executed */
    constructor(string memory initMessage) public {
	message = initMessage;
    }

    /* Main function */
    function update(string memory newMessage) public {
	string memory oldMsg = message;
	message = newMessage;
	emit UpdatedMessages(oldMsg, newMessage);
    }
}