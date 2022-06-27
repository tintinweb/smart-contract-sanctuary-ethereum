/**
 *Submitted for verification at Etherscan.io on 2022-06-26
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title MoodDiary
 * @dev Stores and Retrieves the Mood
*/
contract MoodDiary {
    string public mood;

    /**
     * @dev Store mood in variable
     * @param _mood mood value to store
     */
    function setMood(string memory _mood) public {
        mood = _mood;
    }

    /**
     * @dev Return mood 
     * @return value of 'mood'
     */
    function getMood() public view returns(string memory) {
        return mood;
    }
}