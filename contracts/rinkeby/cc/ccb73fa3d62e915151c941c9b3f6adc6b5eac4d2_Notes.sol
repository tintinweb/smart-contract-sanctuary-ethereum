//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Notes {
    mapping(address => string[]) notes;

    bool private initialized;

    address payable public owner;

    event NoteAdded(address user, string note);

    function init(address _owner) external {
        require(!initialized);
        initialized = true;
        owner = payable(_owner);
    }

    function addNote(string memory note) public {
        notes[msg.sender].push(note);
        emit NoteAdded(msg.sender, note);
    }

    function getNote(address user) public view returns (string[] memory) {
        return notes[user];
    }

    function donate() public payable {}

    function withdraw() public {
        require(msg.sender == owner);
        uint256 balance = address(this).balance;
        owner.transfer(balance);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}