// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract GuestBook {
    event NewNote(address indexed persona, string contenido);

    function addNote(string calldata _contenido) external {
        emit NewNote(msg.sender, _contenido);
    }
}