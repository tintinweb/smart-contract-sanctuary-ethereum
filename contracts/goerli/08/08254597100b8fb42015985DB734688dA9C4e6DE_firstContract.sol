pragma solidity <7.1.0;

contract firstContract {

    event updatedMessage(string oldMsg, string newMsg);

    string public message = "Hello World";

    function updateMessage(string memory newMessage) public {
        string memory oldmsg = message;
        message = newMessage;
        emit updatedMessage(oldmsg, newMessage);
    }

}