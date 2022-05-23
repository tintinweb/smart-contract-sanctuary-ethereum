// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Library is Ownable {
    event NewBookAdded(uint id, string name);
    event BookBorrowed(uint id, address user);
    event BookReturned(uint id, address user);

    struct Book {
        string name;
        uint id;
        uint16 numberOfCopies;
        uint16 availableCopies;
    }

    Book[] private books;
    mapping(uint => address[]) private booksBorrowHistory;
    mapping(string => bool) private bookNameExist;
    mapping(address => mapping(uint => bool)) private borrowedBooks;

    function addBook(string memory _name, uint16 _numberOfCopies) public onlyOwner returns (uint Id){
        require(bookNameExist[_name] != true, "This book is already added.");
		
        uint id = books.length;
        bookNameExist[_name] = true;
        books.push(Book(_name, id, _numberOfCopies, _numberOfCopies));

        emit NewBookAdded(books[id].id, books[id].name);
        return id;
    }

    function updateNumberOfCopies(uint _bookId, uint16 _numberOfCopies) public onlyOwner {
        require(_numberOfCopies >= books[_bookId].numberOfCopies - books[_bookId].availableCopies, "You can't reduce the book copies to a number less than the borrowed ones.");
		
        books[_bookId].availableCopies = books[_bookId].availableCopies + _numberOfCopies - books[_bookId].numberOfCopies;
        books[_bookId].numberOfCopies = _numberOfCopies;
    }

    function borrowBook(uint _bookId) public {
        require(books[_bookId].availableCopies > 0, "Sorry we don't have an available copy of this book at the moment.");
        require(borrowedBooks[msg.sender][_bookId] != true, "Sorry you can't borrow a second coppy of this book.");
        
        books[_bookId].availableCopies--;
        borrowedBooks[msg.sender][_bookId] = true;
        booksBorrowHistory[_bookId].push(msg.sender); //Im not sure if we have to hold every borrowing, but we do

        emit BookBorrowed(_bookId, msg.sender);
    }

    function returnBook(uint _bookId) public {
        require(borrowedBooks[msg.sender][_bookId] == true, "This book is not borrowed from our library.");
        
        books[_bookId].availableCopies++;
        borrowedBooks[msg.sender][_bookId] = false;

        emit BookReturned(_bookId, msg.sender);
    }

    function getBooks() public view returns(Book[] memory) {
        return books;
    }

    function getBookBorrowHistory(uint _bookId) public view returns(address[] memory) {
        return booksBorrowHistory[_bookId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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