/**
 *Submitted for verification at Etherscan.io on 2022-09-17
*/

pragma solidity >= 0.8.17;

contract HelloWorld {
    // events
    // states
    // functions

    event messageChanged(string oldMessage, string newMessage);

    string public message;

    constructor(string memory firstMessage) {
        message = firstMessage;
    }

    function update(string memory newMessage) public {
        string memory oldMessage = message;
        message = newMessage;

        emit messageChanged(oldMessage, newMessage);
    }
}