pragma solidity >=0.7.3;

// Define contract named HelloWorld
contract HelloWorld {
    //Emitted when update function is called
    event UpdatedMessages(string oldStr, string newStr);

    // Declare state variable 'message' of type 'string'
    string public message;

    // Constructor run once on contract deployment
    constructor(string memory initMessage) {
        message = initMessage;
    }

    // Public function that updates 'message' from string arguement
    function update(string memory newMessage) public {
        string memory oldMsg = message;
        message = newMessage;
        emit UpdatedMessages(oldMsg, newMessage);
    }
}