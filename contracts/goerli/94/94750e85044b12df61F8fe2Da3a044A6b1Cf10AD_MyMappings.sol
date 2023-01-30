// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract MyMappings {
    mapping(uint256 => Book) public books;
    mapping(address => mapping(uint256 => Book)) public myBooks;

    address private user;

    struct Book {
        string title;
        string author;
    }

    constructor(address _user) {
        user = _user;
    }

    function addBook(
        uint256 _id,
        string memory _title,
        string memory _author
    ) public {
        books[_id] = Book(_title, _author);
    }

    function addMyBook(
        uint256 _id,
        string memory _title,
        string memory _author
    ) public {
        myBooks[msg.sender][_id] = Book(_title, _author);
    }

    function getUser() external view returns (address) {
        return user;
    }
}