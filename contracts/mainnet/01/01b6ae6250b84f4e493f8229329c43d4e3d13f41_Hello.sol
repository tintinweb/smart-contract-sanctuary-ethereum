// ██   ██ ███████ ██      ██       ██████
// ██   ██ ██      ██      ██      ██    ██
// ███████ █████   ██      ██      ██    ██
// ██   ██ ██      ██      ██      ██    ██
// ██   ██ ███████ ███████ ███████  ██████
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

contract Hello {
    string public message;

    constructor(string memory _message) {
        message = _message;
    }

    function hello() public view returns (string memory) {
        return message;
    }

    function world(string memory _message) public {
        message = _message;
    }
}