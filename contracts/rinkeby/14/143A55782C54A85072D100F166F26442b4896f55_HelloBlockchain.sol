/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

// Name of the contract is MyFirstSmartContract in Pascal case
contract HelloBlockchain{


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
    
    // This function accepts a string argument and stores it in the state variable
    function setMessage(string memory _oldMessage) public{
        welcomeMessage = _oldMessage ;

    }

    // This function returns the last updated value of the state variable
    function viewMessage() public view returns (string memory){

        return welcomeMessage;


    } 
}