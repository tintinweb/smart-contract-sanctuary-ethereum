pragma solidity >= 0.7.3;


contract helloWorld {

    event UpdatedMessage (string oldmsg, string newMessage);
    string public message;

    constructor (string memory initMesssage) {
        message = initMesssage;
    }
    function update (string memory newMessage) public {
        string memory oldmsg = message;
        message  = newMessage;
        emit UpdatedMessage(oldmsg, newMessage);

    }
}