// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

contract HelloWorld {
    // events
    // states
    // functions

    event message_changed(string old_message, string new_message);

    string public message;

    constructor(string memory first_message) {
        message = first_message;
    }

    function update_message(string memory new_message) public {
        string memory old_message = message;
        message = new_message;

        emit message_changed(old_message, new_message);
    }
}