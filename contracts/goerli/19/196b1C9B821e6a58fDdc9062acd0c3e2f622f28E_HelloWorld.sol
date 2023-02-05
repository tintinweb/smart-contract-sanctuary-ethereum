// Specifies the version of solidity.

pragma solidity >=0.7.3;

// stores a message upon creation.
contract HelloWorld {
    
    // Emitted when update function is called.
    event UpdateMessages(string oldStr, string newStr);

    // Declares a state variable 'message'
    string public message;

    constructor(string memory initMessage) {
        message = initMessage;
    }

    function update(string memory newMessage) public {
        string memory oldMsg = message;
        message = newMessage;
        emit UpdateMessages(oldMsg, newMessage);
    }
}