//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Notes {

    mapping(address => string) notes;

    function initialize() public {

    }

    function addNote(string memory note) public {
        notes[msg.sender] = note;
    }

    function getNote() public view returns (string memory)  {
        return notes[msg.sender];
    }
}