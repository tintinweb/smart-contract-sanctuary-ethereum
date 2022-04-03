/**
 *Submitted for verification at Etherscan.io on 2022-04-03
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract BookCatalog{

    event AddBook(address recepient, uint bookId);
    event SetFinished(uint bookId, bool finished);

    struct Book{
        uint id;
        string bookName;
        uint year;
        string author;
        bool finished;
    }

    Book[] private bookList;

    mapping(uint => address) bookToOwner;

    function addBook(string memory _bookName, uint _year, string memory _author, bool _finished) external {
        uint bookId = bookList.length;
        bookList.push(Book(bookId, _bookName,_year,_author,_finished));
        bookToOwner[bookId] = msg.sender;
        emit AddBook(msg.sender,bookId);
    }

    function _getBookList(bool _finished) private view returns (Book[] memory){
        Book[] memory temp = new Book[](bookList.length);
        uint counter = 0;
        for(uint i=0; i<bookList.length; i++){
            if(bookToOwner[i] == msg.sender && bookList[i].finished == _finished){
                temp[counter] = bookList[i];
                counter++;
            }
        }
        Book[] memory result = new Book[](counter);
        for(uint i=0; i<counter; i++){
            result[i] = temp[i];
        }

        return result;
    }

    function getFinishedBooks() external view returns (Book[] memory) {
        return _getBookList(true);
    }

    function getUnfinishedBooks() external view returns (Book[] memory) {
        return _getBookList(false);
    }

    function setFinished(uint bookId, bool finished) external{
        if(bookToOwner[bookId] == msg.sender){
            bookList[bookId].finished = finished;
            emit SetFinished(bookId, finished);
        }
    }

}