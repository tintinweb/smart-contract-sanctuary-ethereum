//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Notes {
    mapping(address => string[]) notes;

    address payable public owner;

    function initialize() public {
        owner = payable(msg.sender);
    }

    function addNote(string memory note) public {
        notes[msg.sender].push(note);
    }

    function getNote(address user) public view returns (string[] memory) {
        return notes[user];
    }

    function donate() public payable {}

    function withdraw() public {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}