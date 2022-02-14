pragma solidity ^0.8.4;

contract HelloWorld {
    // Declares a state variable `message` of type `string`
    // A public declaration makes the variable accessible outside the contract
    string public message;

    // Run once on contract creation
    constructor(string memory initMessage) {
        message = initMessage;
    }

    // A public function that accepts a message and updates the contract's
    // message to be the input
    function update(string memory inMessage) public {
        message = inMessage;
    }
}