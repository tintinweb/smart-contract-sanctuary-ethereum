/**
 *Submitted for verification at Etherscan.io on 2023-02-25
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract FamilplsContract {
    event NewNote(
        address indexed from,
        uint256 timestamp,
        string name,
        string message
    );

    struct Note {
        address from;
        uint256 timestamp;
        string name;
        string message;
    }

    address payable owner;

    Note[] private notes;

    constructor() {
        owner = payable(msg.sender);
    }

    function getNotes() public view returns (Note[] memory) {
        return notes;
    }

    function buyFamilpls(string memory _name, string memory _message) public payable {
        require(msg.value > 0, "Sir please for mi famil.");

        notes.push(Note(
            msg.sender,
            block.timestamp,
            _name,
            _message
        ));

        emit NewNote(
            msg.sender,
            block.timestamp,
            _name,
            _message
        );
    }

    function withdrawFamil() public {
        require(owner.send(address(this).balance));
    }
}