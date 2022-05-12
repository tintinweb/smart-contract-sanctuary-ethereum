// SPDX-License-Identifier: ISC
pragma solidity >=0.8.12;

contract moodDiary {

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

    string mood;
    // create a function that writes a mood to the smart contract
    function setMood(string memory _mood) public {
        mood = _mood;
    }
    // create a function that reads a mood 
    function getMood() public view returns(string memory) {
        return mood;
    }
}