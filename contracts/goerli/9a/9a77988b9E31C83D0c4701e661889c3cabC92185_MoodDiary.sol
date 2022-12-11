// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract MoodDiary {
    // Define a maximum mood string length
    uint256 public MAX_MOOD_LENGTH = 100;

    // Mood struct
    struct Mood {
        // Timestamp
        uint256 timestamp;
        // Mood string
        string mood;
    }

    // Mapping of user addresses to arrays of Mood structs
    mapping(address => Mood[]) public addressToMoods;

    // Function to set a user's current mood
    function setMood(string memory _mood) public {
        // Convert string to bytes to check length
        bytes memory moodBytes = bytes(_mood);
        // Validate the mood string
        require(moodBytes.length > 0, "Mood cannot be empty");
        require(moodBytes.length <= MAX_MOOD_LENGTH, "Mood is too long");

        // Get the user's address
        address user = msg.sender;

        // Create a new Mood struct with the current timestamp and the provided mood string
        Mood memory mood = Mood(block.timestamp, _mood);

        // Add the new Mood struct to the user's array of moods
        addressToMoods[user].push(mood);
    }

    // Function to get a user's most recent mood
    function getMostRecentMood() public view returns (Mood memory) {
        // Get the user's address
        address user = msg.sender;

        // Retrieve the user's array of moods
        Mood[] memory moods = addressToMoods[user];

        // Return the most recent Mood struct
        return moods[moods.length - 1];
    }

    // Function to get a user's entire mood history
    function getMoodHistory() public view returns (Mood[] memory) {
        // Get the user's address
        address user = msg.sender;

        // Return the user's array of moods
        return addressToMoods[user];
    }
}