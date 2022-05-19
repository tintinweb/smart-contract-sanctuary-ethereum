// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestContract {
    string public message;

    /// @notice the first function. sets the message to "first"
    function functionOne() public {
        message = "first";
    }

    /// @notice the second function. sets the message to "second"
    function functionTwo() public {
        message = "second";
    }

    /// @notice This function sets the message to a provided string
    /// @param _msg The string which the message will be set to.
    function setMessage(string memory _msg) public {
        message = _msg;
    }
}