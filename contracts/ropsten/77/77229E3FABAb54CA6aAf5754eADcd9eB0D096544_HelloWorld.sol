// SPDX-License-Identifier: MIT

pragma solidity >= 0.7.3;

// Contract structure: state, functions, events
contract HelloWorld {

    event UpdatedMessages(string oldStr, string newStr);

    string public message; //state variable; permanently stored in the blockchain; anyone can access it

    //The Ethereum Virtual Machine has three areas where it can store data: storage, memory and the stack
    //memory - cannot be used at the contract level. Only in methods.
    //memory tells solidity to create a chunk of space for the variable at method runtime, guaranteeing its size and structure for future use in that method.
    constructor(string memory initMessage) { //runs only when smart contract is deployed
        message = initMessage;
    } 

    function update(string memory newMessage) public {
        string memory oldMsg = message;
        message = newMessage;
        emit UpdatedMessages(oldMsg, newMessage);
    }
}