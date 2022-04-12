//what opensource license !important
//SPDX-License-Identifier: MIT

// What version of solidity?
pragma solidity >= 0.7.3;

contract HelloWorld {
    event UpdatedMessages(string oldStr, string newStr);

    // state variable, would be stored permanently on the blockchain
    string public message;

    // allow the contract to be called with a setup value 
    // in this case pass initMessage to message(state var)
    constructor (string memory initMessage) {
        message = initMessage;
    }

    function update(string memory newMessage) public {
        string memory oldMsg = message;
        message = newMessage;
        emit UpdatedMessages(oldMsg, newMessage);
    }

}