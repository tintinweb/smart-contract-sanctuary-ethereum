// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BookLibrary is Ownable {
    struct Book {
        uint8 copies;
        string title;
        address[] bookBorrowedAddresses;
    }

    bytes32[] public bookKey;

    mapping (bytes32 => Book) public books;
    mapping (address => mapping(bytes32 => bool)) public borrowedBook;

    event LogAddedBook(string title, uint copies);
    event LogBookBorrowed(string title, address user);
    event LogBookReturned(string title, address user);

    modifier validBookData(string memory _title, uint8 _copies) {
        bytes memory tempTitle = bytes(_title);
        require(tempTitle.length > 0 && _copies > 0, "Book data is not valid.");
        _;
    }

    modifier bookDoesNotExist(string memory _title) {
        require(bytes(books[keccak256(abi.encodePacked(_title))].title).length == 0, "This book is already added");
        _;
    }

    function addBook(string memory _title, uint8 _copies) public onlyOwner validBookData(_title, _copies) bookDoesNotExist(_title) {
        bytes32 bookNameEncoded = keccak256(abi.encodePacked(_title));
        address[] memory borrowed;
        Book memory newBook = Book(_copies, _title, borrowed);
        books[bookNameEncoded] = newBook;
        bookKey.push(bookNameEncoded);

        emit LogAddedBook(_title, _copies);
    }

    function borrowBook(bytes32 bookId) public {
        Book storage book = books[bookId];

        require(book.copies > 0, "There is no copies from this book left");

        require(!borrowedBook[msg.sender][bookId], "This book is already borrowed by you");

        borrowedBook[msg.sender][bookId] = true;
        book.bookBorrowedAddresses.push(msg.sender);
        book.copies--;
        emit LogBookBorrowed(book.title, msg.sender);
    }

    function returnBook(bytes32 bookId) public {
        Book storage book = books[bookId];

        require(borrowedBook[msg.sender][bookId], "You can't return a book that you haven't borrowed");

        borrowedBook[msg.sender][bookId] = false;
        book.copies++;

        emit LogBookReturned(book.title, msg.sender);
    }

    function getAllAddressesBorrowedBook(bytes32 bookId) public view returns(address[] memory _book) {
        Book memory book = books[bookId];
        return book.bookBorrowedAddresses;
    }

    function getAvailableBooks() public view returns(Book[] memory) {
        uint8 counter = 0;
        for (uint i = 0; i < bookKey.length ; i++) {
            bytes32 currentBookKey = bookKey[i];
            Book memory currentBook = books[currentBookKey];
            if (currentBook.copies > 0) {
                counter++;
            }
        }

        Book[] memory availableBooks = new Book[](counter);

        for (uint i; i < bookKey.length; i++) {
            if (books[bookKey[i]].copies > 0) {
                availableBooks[i] = books[bookKey[i]];
            }
        }

        return availableBooks;
    }
}