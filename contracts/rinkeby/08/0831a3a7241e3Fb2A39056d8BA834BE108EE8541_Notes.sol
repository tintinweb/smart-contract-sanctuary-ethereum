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

    function getNote() public view returns (address)  {
        // string memory note = notes[msg.sender];
        // string memory note = notes[address(this)];
        return msg.sender;
    }

    int a;

    function getCount() public view returns (int) {
        return a;
    }

    function increment() public {
        a = a + 1;
    }
}