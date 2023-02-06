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
pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BookStore is Ownable{
    // Book struct
    struct Book {
        string title;
        uint copies;
        address[] borrowers;
    }

    // Books IDs
    bytes32[] public booksId;
    
    // Mapping from book id to book struct
    mapping(bytes32 => Book) public books;

    // Nested mapping for borrowed books from user address by booksId
    mapping(address => mapping(bytes32 => bool)) public borrowedBook;

    // Event for book added
    event BookAdded(bytes32 id, string title, uint copies);

    // Event for book borrowed
    event BookBorrowed(bytes32 id, address borrower);

    // Event for book returned
    event BookReturned(bytes32 id, address borrower);

    // Function to add a book
    function addBook(string memory _title, uint _copies) public onlyOwner{
        // Generate book id
        bytes32 newBookId = keccak256(abi.encodePacked(_title, block.timestamp));

        // Add book id to the booksId array
        booksId.push(newBookId);

        // Add the book to the books mapping
        books[newBookId] = Book(_title, _copies, new address[](0));

        // Emit BookAdded event
        emit BookAdded(newBookId, _title, _copies);
    }

    // Function to borrow a book
    function borrowBook(bytes32 _id) public {
        // Check if book has free copies available
        require(books[_id].copies > 0, "No copies available.");
  
        // Check if the user has already borrowed the book
        require(borrowedBook[msg.sender][_id] == false, "You have already borrowed this book.");

        // Decrease the amount of available copies to borrow
        books[_id].copies--;

        // Push msg.sender to borrowers array
        books[_id].borrowers.push(msg.sender);

        // Set msg.sender as active borrower of this book
        borrowedBook[msg.sender][_id] = true;

        // Emit BookBorrowed Event
        emit BookBorrowed(_id, msg.sender);
    }

    // Function to return a book
    function returnBook(bytes32 _id) public {
        // Check if the user has borrowed the book
        require(borrowedBook[msg.sender][_id] == true , "You have not borrowed this book."); 
        
        // Increase the amount of available copies to borrow
        books[_id].copies++;

        // Remove msg.sender as active borrower of this book
        borrowedBook[msg.sender][_id] = false;

        // Emit BookReturned Event
        emit BookReturned(_id, msg.sender);
    }

    // Function to get the borrowers history of a book
    function getBorrowersHistory(bytes32 _id) public view returns (address[] memory) {
        return books[_id].borrowers;
    }

    //Function to return the number of books in stored the library
    function getNumberOfBooks() public view returns (uint){
        return booksId.length;
    }
}