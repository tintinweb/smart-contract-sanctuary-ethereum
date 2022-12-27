//SPDX-Licenece-Identifier: MIT

pragma solidity >= 0.8.17;

contract CumLand {
    event UpdatedMessages(string oldStr, string newStr);
    string public message;
    constructor(string memory initMessage) {
        message = initMessage;
    }

    function update(string memory newMessage) public {
        string memory oldMsg = message;
        message = newMessage;
        emit UpdatedMessages(oldMsg, newMessage);
    }
}