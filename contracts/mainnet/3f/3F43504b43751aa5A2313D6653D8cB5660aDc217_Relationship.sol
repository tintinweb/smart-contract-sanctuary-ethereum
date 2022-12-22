// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Relationship {
    address public personOne;
    address public personTwo;
    string public relationshipDescription;
    bool public agreedByPersonTwo;
    bool public active;

    constructor(address _personTwo, string memory _relationshipDescription) {
        require(_personTwo != msg.sender);
        personOne = msg.sender;
        personTwo = _personTwo;
        relationshipDescription = _relationshipDescription;
        agreedByPersonTwo = false;
        active = true;
    }

    function agree() public {
        require(personTwo == msg.sender, "It is not for you to agree!");
        require(!agreedByPersonTwo, "You already agreed to this relationship!");
        agreedByPersonTwo = true;
    }

    function disactivate() public {
        require(
            personOne == msg.sender || personTwo == msg.sender,
            "You are not involved in this relationship!"
        );
        require(active, "The relationship is already ended!");
        active = false;
    }

    function update(string memory _newRelationshipDescription) public {
        require(
            personOne == msg.sender || personTwo == msg.sender,
            "You are not involved in this relationship!"
        );
        require(active, "The relationship has already ended!");
        if (personTwo == msg.sender) {
            personTwo = personOne;
            personOne = msg.sender;
        }
        relationshipDescription = _newRelationshipDescription;
        agreedByPersonTwo = false;
    }
}