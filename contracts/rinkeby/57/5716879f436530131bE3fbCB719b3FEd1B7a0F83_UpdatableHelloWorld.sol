// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

/**
* @title An updatable hello world contract
* @author kyrers
* @notice You can use this contract to update the message that getLatestMessage() emits;
* @dev This might not be the most efficient way of implementing this
*/
contract UpdatableHelloWorld {
    //##### VARIABLES #####

    //Array of messages
    string[] public messages;

    //The latest address to update the message
    address public latestSubmitter;

    //Mapping between users and their messages
    mapping(address => string[]) userMessages;


    //##### EVENTS #####
    
    //Emit the latest message and the user who created it
    event LatestMessage(address user, string message);
    

    //##### FUNCTIONS #####

    /**
    * @notice Contract constructor. Sets the initial message, submitter and updates the mapping
    * @param _initialMessage The initial message
    */
    constructor(string memory _initialMessage) {
        messages.push(_initialMessage);
        latestSubmitter = msg.sender;
        userMessages[msg.sender].push(_initialMessage);
    }

    /**
    * @notice Update the current mesage, latest submitter and the mapping. Finally, emit the LatestMessage event.
    * @param _newMessage The initial message
    */
    function updateMessage(string memory _newMessage) external {
        messages.push(_newMessage);
        userMessages[msg.sender].push(_newMessage);
        latestSubmitter = msg.sender;
        emit LatestMessage(latestSubmitter, _newMessage);
    }

    /**
    * @notice Get the latest message and who submitted it
    * @return The latest message
    * @return The latest submitter
    */
    function getLatestMessage() external view returns (string memory, address) {
        return (messages[messages.length - 1], latestSubmitter);
    }

    /**
    * @notice Get a specific address message.
    * @param _user The user whose message is wanted
    * @param _index The message index in the mapping string array
    * @return The message
    */
    function getUserMessage(address _user, uint _index) external view returns (string memory) {
        return userMessages[_user][_index];
    }
}