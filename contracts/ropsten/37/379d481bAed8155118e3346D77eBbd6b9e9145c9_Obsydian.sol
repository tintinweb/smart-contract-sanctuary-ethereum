// Congratulations! You found me. This is my very first smart contract and I used the Ethereums Foundation's 'Hello World!' smart contract tutorial to make it! 
// If you have found this, that means that you have heard of me, my first project has already been released or will release soon, and can be found on the secondary markets. 
// I have a very important message to share to the lucky individual who found this: my first free project will serve as an exclusive allowlist pass for all of my future projects. 
// My goal in this space is to make a lasting impact. Whether it be through innovative technology, inspiring, thought provoking, or funny artwork, or even as a friendly and welcoming face in the community. 
// All of my subsequent projects will attempt to display these values and goals. I am happy that you found me and look forward to getting to know you all as members of my community! 
// Take care, have fun, and remember to spend time with loved ones. I will see you again soon! - Obsydian

// Specifies the version of Solidity, using semantic versioning.

pragma solidity >=0.7.3; // Any version of solidity 0.7.3 or later

// Define the contract
contract Obsydian {
    
    // Events are a way for the smart contract to communicate when a method has been called. Will be emitted when the update function is called.
    event UpdateMessages(string oldStr, string newStr);
    
    // Declare a publicly visible state variable 'message' of type 'string'
    string public message;
    
    // Executed during contract creation. Initializes the contract's data.
    constructor(string memory initMessage) {
        
        // Constructor will set the string argument 'initMessage' into the contracts stored variable 'message' upon contract creation.
        message = initMessage;
    }
        
    // Public function that accepts a string argument and updates the 'message' storage variable.
    function update(string memory newMessage) public {
        string memory oldMsg = message;
        message = newMessage;
        emit UpdateMessages(oldMsg, newMessage);
    }

}