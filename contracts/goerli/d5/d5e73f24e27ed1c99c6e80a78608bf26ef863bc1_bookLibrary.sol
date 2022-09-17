/**
 *Submitted for verification at Etherscan.io on 2022-09-17
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract bookLibrary {
    address public contractOwner;

    constructor() {
        contractOwner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwner);
        _;
    }

    struct Book {
        uint256 id;
        string name;
        string author;
        uint256 price;
    }

    mapping(uint256 => Book) public books;

    function addBook(uint256 _bookId,string memory _bookName,string memory _bookAuthor,uint256 _price) public onlyOwner
    {
        books[_bookId].name = _bookName;
        books[_bookId].author = _bookAuthor;
        books[_bookId].price = _price;
    }

    function queryBookById(uint256 _bookId)
        public view returns (
            string memory name,
            string memory author,
            uint256 price
        )
    {
        return (
            books[_bookId].name,
            books[_bookId].author,
            books[_bookId].price
        );
    }
}