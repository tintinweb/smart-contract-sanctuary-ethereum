// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Cards {
    struct Card {
        string title;
        string description;
        string dueDate;
        string status;
        string details;
        string imgUrl;
    }

    uint32 public totalCards = 0;
    mapping(uint256 => Card) public cards;

    event NewCard(
        string title,
        string description,
        string dueDate,
        string status,
        string details,
        string imgUrl
    );

    function newCard(
        string memory _title,
        string memory _description,
        string memory _dueDate,
        string memory _status,
        string memory _details,
        string memory _imgUrl
    ) public {
        totalCards++;
        cards[totalCards] = Card(_title, _description, _dueDate, _status, _details, _imgUrl);

        emit NewCard(_title, _description, _dueDate, _status, _details, _imgUrl);
    }

    function getCard(uint256 _id) public view returns (Card memory) {
        return cards[_id];
    }

    function updateCard(
        string memory _title,
        string memory _description,
        string memory _dueDate,
        string memory _status,
        string memory _details,
        string memory _imgUrl,
        uint256 _id
    ) public {
        Card storage card = cards[_id];
        card.title = _title;
        card.description = _description;
        card.dueDate = _dueDate;
        card.status = _status;
        card.details = _details;
        card.imgUrl = _imgUrl;
    }

    function deleteCard(uint256 _id) public {
        delete cards[_id];
    }
}