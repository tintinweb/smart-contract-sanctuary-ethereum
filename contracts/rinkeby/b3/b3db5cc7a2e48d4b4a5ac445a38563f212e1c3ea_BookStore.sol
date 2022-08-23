/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract BookStore {

    address owner;

    struct Book {
        string title;
        string author;
        uint price;
        address seller;
    }

    modifier isOwner {
        require(msg.sender == owner);
        _;
    }

    mapping (address => Book[]) books;

    constructor() {
        owner = msg.sender;
    }

    function addBook(string memory title, string memory author, uint price) public {
        Book memory book = Book(title, author, price, msg.sender);
        books[msg.sender].push(book);
    }

    function getBooks() public view returns (Book[] memory) {
        return books[msg.sender];
    }



}