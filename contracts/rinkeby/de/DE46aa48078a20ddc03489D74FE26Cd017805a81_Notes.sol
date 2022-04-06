//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Notes {

    mapping(address => string) notes;

    int a;

    function initialize() public {
    }

    function addNote(string memory note) public {
        notes[msg.sender] = note;
    }

    function getNote() public pure returns (string memory)  {
        // string memory note = notes[msg.sender];
        // string memory note = notes[address(this)];
        return "sinep";
    }

    function myAddress() public view returns (address){
        return msg.sender;
    }

}