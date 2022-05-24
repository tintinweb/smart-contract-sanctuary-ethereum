// SPDX-License-Identifier: MIT

pragma solidity >= 0.7.3;

// hardhat compile -- npx hardhat compile
// deploy/run contract -- npx hardhat run scripts/deply.js --network rinkeby

contract HelloWorld {
    // Pass in old string and update with new string when event is called.
    event UpdatedMessages(string oldStr, string newStr);

    // State variable that is public to anyone on blockchain to access - stored permanently on blockchain.
    string public message;

    // When contract is deployed initially, we require an argument to be passed into it as well.
    // Once called, our state variablie 'message' will be assigned to the string argument that was originally passed in.
    constructor (string memory initMessage) {
        message = initMessage;
    }

    // Function will update the new string user passed in with previous string stored in 'message'.
    // Uses the event function 'UpdatedMessages' to update 'message' var
    function update(string memory newMessage) public {
        // Memory - A temporary place to store data 
        // Storage - holds data b/w function calls
        // Smart Contract can use any amount of memory during execution but once execution stops, 
        // the memory is completely wiped off for the next execution. But storage is persistent - SM has access to data prev stored
        // on storage area.
        // Gas consumption of memory is no significant, when compared to gas consumption of Storage.
        // Better to use Memory for intermediate calculations and store the final result in Storage.
        string memory oldMsg = message;
        message = newMessage;
        emit UpdatedMessages(oldMsg, newMessage);

    }
}