//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Notes {

    mapping(address => string) notes;

    function initialize() public {
        notes[address(this)] = "sinep";
    }

    function addNote(string memory note) public {
        notes[msg.sender] = note;
    }

    function getNote() public view returns (string memory)  {
        // string memory note = notes[msg.sender];
        string memory note = notes[address(this)];
        return note;
    }

    function sinep() public pure returns (string memory) {
        return "sinep";
    }
}