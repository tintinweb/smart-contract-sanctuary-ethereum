// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Library is Ownable {

    struct Book {
        uint8 copies;
        string title;
        address[] bookBorrowedAddresses;
    }

    bytes32[] public bookId;

    mapping(bytes32 => Book) public books;
    mapping(address => mapping(bytes32 => bool)) public borrowedBook;

    event LogAddedBook(string title, uint copies);

    event LogBorrowedBook(string title, address borrower);

    event LogBookReturned(string title, address borrower);

    modifier validBookData(string memory _title, uint8 _copies) {
        bytes memory tempTitle = bytes(_title);
        require(tempTitle.length > 0, "The title of the book can not be empty");
        require(_copies > 0, "The amount of books to be added should be positive");
        _;
    }

    modifier bookDoesNotExist(string memory _title) {
        require(bytes(books[keccak256(abi.encodePacked(_title))].title).length == 0, "This book is already added");
        _;
    }

    function addBooks(string memory _title, uint8 _copies) public onlyOwner validBookData(_title, _copies) bookDoesNotExist(_title) {
        address[] memory borrowed;
        Book memory newBook = Book(_copies, _title, borrowed);
        bytes32 newBookHash = keccak256(abi.encodePacked(_title));
        books[newBookHash] = newBook;
        bookId.push(newBookHash);
        emit LogAddedBook(_title, _copies);
    }

    function reserveBook(bytes32 _desiredBookId) public {
        Book storage book = books[_desiredBookId];

        require(book.copies > 0, "There are no copies left for this book");

        require(!borrowedBook[msg.sender][_desiredBookId], "You have already borrowed the book");

        borrowedBook[msg.sender][_desiredBookId] = true;
        book.bookBorrowedAddresses.push(msg.sender);
        book.copies -= 1;

        emit LogBorrowedBook(book.title, msg.sender);
    }

    function returnBook(bytes32 _bookId) public {
        Book storage book = books[_bookId];

        require(borrowedBook[msg.sender][_bookId], "You can not return a book you haven't borrowed");

        borrowedBook[msg.sender][_bookId] = false;
        book.copies += 1;

        emit LogBookReturned(book.title, msg.sender);
    }

    function getAllAddressBorrowedBook(bytes32 _bookId) public view returns(address[] memory _book) {
        Book memory book = books[_bookId];
        return book.bookBorrowedAddresses;
    }

}