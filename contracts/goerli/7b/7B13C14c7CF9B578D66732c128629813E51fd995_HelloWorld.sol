// SPDX-License-Identifier: MIT
pragma solidity >=0.7.3;

/// @title The title
/// @author The author
/// @notice The comments for the end-users
/// @dev The comments for the devs
contract HelloWorld {

    string message;

    constructor() {
        message = "Hello world!";
    }

    /// @notice The second comments for the end-users
    /// @dev The second comments for the devs
    /// @param _message The comments for the arguments of the function
    function setMessage(string memory _message) public {
        message = _message;
    }

    /// @return The comments for the return of the function
    function getMessage() public view returns(string memory) {
        return message;
    }
}