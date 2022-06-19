// SPDX-License-Identifier: MIT >> The file needs to know what open source license this file has. Whether or not it even has one.

pragma solidity >= 0.7.3; // what version of solidity do we need to run this code?

contract HelloWorld {
    event UpdateMessages(string oldStr, string newStr); // when the event happens, people will be able to see new/old string

    string public message; //everyone can read this variable, and will be stored permanently on the blockchain

    constructor (string memory initMessage) { //constructor is only run once when the smart contract is deployed and we require the initMessage "Initial message"
        message = initMessage;
    }

    function update(string memory newMessage) public { //updates state variable in the contract - access level of the function is public
        string memory oldMsg = message;
        message = newMessage;
        emit UpdateMessages(oldMsg, newMessage);
    }

}