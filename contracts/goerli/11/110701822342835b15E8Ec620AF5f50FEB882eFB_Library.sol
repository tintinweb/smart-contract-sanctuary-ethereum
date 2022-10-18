// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Book.sol";
import "./Utils.sol";

contract Library {
    using BookUtils for Book;
    using StringUtils for string;

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can do that");
        _;
    }

    struct Copy {
        uint256 _id;
        string _isbn;
        bool _isValid;
        address _holder;
    }

    mapping(string => Book) public bookByIsbn;
    string[] public bookIsbns;

    uint256 private _nextCopyId;
    mapping(uint256 => Copy) public copies;

    function getBookIsbnsLength()
        public
        view
        returns (uint256 bookIsbnsLength)
    {
        return bookIsbns.length;
    }

    function addBook(
        string memory title,
        string memory authorFirstName,
        string memory authorLastName,
        string memory isbn
    ) public onlyOwner {
        Book storage book = bookByIsbn[isbn];
        book._isValid = true;
        book._isbn = isbn;
        book._title = title;
        book._authorFirstName = authorFirstName;
        book._authorLastName = authorLastName;

        bookIsbns.push(isbn);
    }

    function removeBook(string memory isbn) public onlyOwner {
        Book storage book = bookByIsbn[isbn];
        require(book._isValid, "Invalid book");
        require(book.copyIds.length == 0, "Book has copies");
        book._isValid = false;
        delete bookByIsbn[isbn];

        for (uint256 i = 0; i < bookIsbns.length; i++) {
            if (bookIsbns[i].equals(isbn)) {
                bookIsbns[i] = bookIsbns[bookIsbns.length - 1];
                bookIsbns.pop();
                break;
            }
        }
    }

    function addCopy(string memory isbn) public onlyOwner {
        Book storage book = bookByIsbn[isbn];
        require(book._isValid, "Invalid book");
        uint256 copyId = _nextCopyId++;
        Copy storage copy = copies[copyId];
        copy._id = copyId;
        copy._isValid = true;
        copy._isbn = isbn;
        book.copyIds.push(copyId);
    }

    function deleteCopy(string memory isbn, uint256 copyId) public onlyOwner {
        Book storage book = bookByIsbn[isbn];
        require(book._isValid, "Invalid book");
        Copy storage copy = copies[copyId];
        require(copy._isValid, "Invalid copy");
        require(copy._holder == address(0), "Copy is held");
        copy._isValid = false;
        book.removeCopy(copyId);
        delete copies[copyId];
    }

    function getCopyIdsByIsbn(string memory isbn)
        public
        view
        returns (uint256[] memory)
    {
        return bookByIsbn[isbn].copyIds;
    }

    function issueCopy(
        string memory isbn,
        uint256 copyId,
        address holder
    ) public onlyOwner {
        require(holder != address(0), "Invalid holder");
        Book storage book = bookByIsbn[isbn];
        require(book._isValid, "Invalid book");
        Copy storage copy = copies[copyId];
        require(copy._isValid, "Invalid copy");
        require(copy._holder == address(0), "Already held");
        copy._holder = holder;
    }

    function returnCopy(
        string memory isbn,
        uint256 copyId,
        address holder
    ) public onlyOwner {
        require(holder != address(0), "Invalid holder");
        Book storage book = bookByIsbn[isbn];
        require(book._isValid, "Invalid book");
        Copy storage copy = copies[copyId];
        require(copy._isValid, "Invalid copy");
        require(copy._holder == holder, "Holder mismatches");
        copy._holder = address(0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

struct Book {
    bool _isValid;
    string _isbn;
    string _title;
    string _authorFirstName;
    string _authorLastName;
    uint256[] copyIds;
}

library BookUtils {
    function getCopyIndex(Book storage book, uint256 copyId)
        internal
        view
        returns (uint256, bool)
    {
        for (uint256 i = 0; i < book.copyIds.length; i++) {
            if (book.copyIds[i] == copyId) {
                return (i, true);
            }
        }
        return (0, false);
    }

    function removeCopyByIndex(Book storage book, uint256 copyIndex) internal {
        book.copyIds[copyIndex] = book.copyIds[book.copyIds.length - 1];
        book.copyIds.pop();
    }

    function removeCopy(Book storage book, uint256 copyId) internal {
        uint256 copyIndex;
        bool copyFound;
        (copyIndex, copyFound) = getCopyIndex(book, copyId);
        require(copyFound, "No matches in copyIds array");
        removeCopyByIndex(book, copyIndex);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library StringUtils {
    function equals(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
}