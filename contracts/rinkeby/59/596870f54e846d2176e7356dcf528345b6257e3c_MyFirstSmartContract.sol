/**
 *Submitted for verification at Etherscan.io on 2022-03-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

// Name of the contract is MyFirstSmartContract in Pascal case
contract MyFirstSmartContract{

    // Events happen when an action takes place. In this case, the message is updated when the event is trggered. In this event,  a new message replaces an old message
    //The emit keyword is used to talk to an event.
    event updateMessage(string oldMessage, string newMessage);

    // This is a state variable named welcomeMessage. The values of state variables are permanently stored in the contract's storage.
    // The qualifier public, ensures that the variable can be accesssed from outside the contract. and creates a function that other contracts or clients can call to access the value
    string public welcomeMessage;

    // A constructor is a special function that is executed upon creation of the contract
    //Let's just say that a constructor initializes the data stored in the contract 
    // In this case, it initializes the state variable "welcomeMessage"
    constructor(string memory _welcomeMessage){

        // Accepts a string argument "_welcomeMessage" and stores the value into the contract's "message" storage variable
        welcomeMessage = _welcomeMessage;

    }
    
    // This function accepts a string argument and updates the "message" storage variable
    function setMessage(string memory _newMessage) public{
        string memory oldMsg = welcomeMessage;
        welcomeMessage = _newMessage;

        // The emit keyword is used to release the value of the argument to the client's side. That is, the value of the argument is passed to the event which can be seen on the frontend of the application (DAPP)
        emit updateMessage(oldMsg, _newMessage);

    } 
}