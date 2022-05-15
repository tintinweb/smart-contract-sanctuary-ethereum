// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./Ownable.sol";

contract Library is Ownable {
    struct Book {
        string name;
        uint8 copies;
        address[] borrowedBy;
    }

    string[] private bookIds;

    mapping(string => Book) private bookIdToBook;
    /// @dev keeps track of the books that has available copies to borrow
    mapping(string => bool) private availableBooks;
    /// @dev keeps track of the books that are registered in the library
    mapping(string => bool) private registeredBooks;
    /// @dev keeps track of the block number of the books borrowed by specific user
    mapping(string => mapping(address => uint))
        private bookBorrowedAtBlockNumber;

    /// @dev emits when book has been added
    event BookAdded(Book book);
    /// @dev emits when already registered book has new copies added
    event BookCopiesAdded(Book book, uint8 copies);
    /// @dev emits when book was borrowed by user
    event BookBorrowed(Book book, address user);
    /// @dev emits when book was returned by user
    event BookReturned(Book book, address user);

    /**
        @dev Add new book, or increase the availabe copies it it exist in the library
    */
    function addBook(string memory _bookId, uint8 _copies) external onlyOwner {
        require(
            _copies > 0,
            "The book should have at least one copy to be added!"
        );

        if (registeredBooks[_bookId] == false) {
            registeredBooks[_bookId] = true;
            bookIdToBook[_bookId] = Book({
                name: _bookId,
                copies: _copies,
                borrowedBy: new address[](0)
            });
            bookIds.push(_bookId);

            emit BookAdded(bookIdToBook[_bookId]);
        } else {
            bookIdToBook[_bookId].copies =
                bookIdToBook[_bookId].copies +
                _copies;

            emit BookCopiesAdded(bookIdToBook[_bookId], _copies);
        }
        _adjustBookAvailability(_bookId);
    }

    /**
        @dev Borrow book if it has available copies and is not borrowed by the user at the moment
    */
    function borrowBook(string memory _bookId) external {
        Book storage _book = bookIdToBook[_bookId];

        require(
            _book.copies > 0,
            "The book has no available copies at the moment!"
        );
        require(
            bookBorrowedAtBlockNumber[_bookId][msg.sender] == 0,
            "The book is currently borrowed by this user!"
        );

        _book.borrowedBy.push(msg.sender);
        _book.copies--;
        bookBorrowedAtBlockNumber[_bookId][msg.sender] = block.number;
        _adjustBookAvailability(_bookId);

        emit BookBorrowed(bookIdToBook[_bookId], msg.sender);
    }

    /**
        @dev Return book, if was borrowed by the user and the it is returned on time (less than 100 blocks away)
    */
    function returnBook(string memory _bookId) external {
        Book storage _book = bookIdToBook[_bookId];

        require(
            bookBorrowedAtBlockNumber[_bookId][msg.sender] != 0,
            "The book is not borrowed by this user!"
        );
        require(
            block.number - bookBorrowedAtBlockNumber[_bookId][msg.sender] < 100,
            "The book was not returned on time!"
        );

        bookBorrowedAtBlockNumber[_bookId][msg.sender] = 0;
        _book.copies++;
        _adjustBookAvailability(_bookId);

        emit BookReturned(bookIdToBook[_bookId], msg.sender);
    }

    /**
        @dev Returns all books registered in the Library.
    */
    function getAllBooks() external view returns (string[] memory) {
        return bookIds;
    }

    /**
        @dev Returns all book registered in the Library.
    */
    function isBookAvailable(string memory _bookId)
        external
        view
        returns (bool)
    {
        return availableBooks[_bookId];
    }

    /**
        @dev Returns array of addresses that has evere borrowed the book by the passed id.
    */
    function getBorrowedAddressesForBook(string memory _bookId)
        external
        view
        returns (address[] memory)
    {
        return bookIdToBook[_bookId].borrowedBy;
    }

    /**
        @dev Adjust the mapping that keeps track of the books that has available copies to borrow.
    */
    function _adjustBookAvailability(string memory _bookId) private {
        if (
            availableBooks[_bookId] == false && bookIdToBook[_bookId].copies > 0
        ) {
            availableBooks[_bookId] = true;
        } else if (
            availableBooks[_bookId] == true && bookIdToBook[_bookId].copies == 0
        ) {
            availableBooks[_bookId] = false;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Ownable {
    address internal owner;

    modifier onlyOwner() {
        require(owner == msg.sender, "Not invoked by the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }
}