// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

contract Greeter {
    /// @notice Emitted when upon a valid greet.
    event LogGreet();

    /// @notice Thrown when a bad greet is requested.
    error BadGmError();

    /// @notice The greeting message.
    string public greeting;

    /// @dev Constructor function that sets the greeting message.
    /// @param newGreeting The greeting message to be set.
    constructor(string memory newGreeting) {
        greeting = newGreeting;
    }

    /// @notice Function to greet everyone with a given message.
    /// @param myGm The message to be used for greeting.
    /// @return greet_ The message used for greeting.
    function greet(string memory myGm) external returns (string memory greet_) {
        if (keccak256(abi.encodePacked((myGm))) != keccak256(abi.encodePacked((greet_ = greeting)))) {
            revert BadGmError();
        }
        emit LogGreet();
    }

    /// @notice Sets the greeting message.
    /// @param newGreeting The new greeting message.
    function setGreeting(string memory newGreeting) external {
        greeting = newGreeting;
    }
}