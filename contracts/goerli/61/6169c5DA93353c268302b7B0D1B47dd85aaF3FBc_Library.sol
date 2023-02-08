// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./LibraryHistory.sol";
import "./LibraryEvents.sol";

contract Library is Ownable, LibraryHistory, LibraryEvents {
    struct Book {
        uint256 id;
        string name;
        string author;
        uint16 copies;
        uint16 availableCopies;
    }

    uint48 private _counter = 0;
    uint48 private _availableBooksCounter = 0;

    mapping(uint256 => Book) private _idToBook;

    mapping(address => mapping(uint256 => bool))
        private _addressCurrentlyBorrowed;

    modifier requireAddressCurrentlyBorrowedBook(
        uint256 _bookId,
        bool requirement
    ) {
        require(
            _addressCurrentlyBorrowed[msg.sender][_bookId] == requirement,
            "You do not meet the book requirement."
        );
        _;
    }

    function addBook(
        string memory _name,
        string memory _author,
        uint16 _copies
    ) public onlyOwner {
        Book memory book = Book(_counter, _name, _author, _copies, _copies);
        _idToBook[_counter] = book;

        emit BookAdded(_counter, _name);

        _counter++;
        _availableBooksCounter++;
    }

    function getAvailableBooks() external view returns (Book[] memory) {
        Book[] memory availableBooks = new Book[](_availableBooksCounter);
        uint256 _booksAdded = 0;

        for (uint256 i = 0; i <= _counter; i++) {
            if (_idToBook[i].availableCopies > 0) {
                availableBooks[_booksAdded] = _idToBook[i];
                _booksAdded++;
            }
        }

        return availableBooks;
    }

    function borrowBook(uint256 _bookId)
        external
        requireAddressCurrentlyBorrowedBook(_bookId, false)
        returns (Book memory)
    {
        require(
            _idToBook[_bookId].availableCopies > 0,
            "There are no available copies left."
        );

        Book storage bookToBorrow = _idToBook[_bookId];
        bookToBorrow.availableCopies--;

        if (bookToBorrow.availableCopies == 0) {
            _availableBooksCounter--;
        }

        _addressCurrentlyBorrowed[msg.sender][_bookId] = true;
        _addBookHistory(_bookId, msg.sender);

        return bookToBorrow;
    }

    function returnBook(uint256 _bookId)
        external
        requireAddressCurrentlyBorrowedBook(_bookId, true)
    {
        Book storage bookToReturn = _idToBook[_bookId];
        if (bookToReturn.availableCopies == 0) {
            _availableBooksCounter++;
        }
        bookToReturn.availableCopies++;

        _addressCurrentlyBorrowed[msg.sender][_bookId] = false;

        emit BookReturned(_bookId, bookToReturn.name);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract LibraryEvents {
    event BookAdded(uint bookId, string name);  
    event BookReturned(uint bookId, string name);  
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract LibraryHistory {
    mapping(uint => address[]) internal _bookBorrowHistory;

    mapping(address => mapping(uint => bool)) internal _addressEverBorrowed;

    function _addBookHistory(uint _bookId, address userAddress) internal {
        if(_addressEverBorrowed[userAddress][_bookId] == false) {
            _addressEverBorrowed[userAddress][_bookId] = true;
            _bookBorrowHistory[_bookId].push(userAddress);
        }
    }

    function getBookHistory(uint _bookId) external view returns(address[] memory) {
        return _bookBorrowHistory[_bookId];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Ownable {
    address public owner;
    
    modifier onlyOwner() {
        require(owner == msg.sender, "Not invoked by the owner");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
}