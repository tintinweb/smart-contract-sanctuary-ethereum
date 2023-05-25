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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";

error InvalidId();
error InsufficientCopies();
error BookAlreadyBorrowed();
error BookNotBorrowed();

contract Library is Ownable {
    Book[] private books;
    mapping(uint256 => address[]) public usersByBook;
    mapping(address => mapping(uint256 => bool)) public borrowedBooks;

    struct Book {
        uint256 id;
        string title;
        string author;
        uint256 copies;
    }

    event BookAdded(
        uint256 indexed id,
        string title,
        string author,
        uint256 copies
    );
    event CopiesIncreased(uint256 indexed id, uint256 copies);
    event BookBorrowed(
        uint256 indexed id,
        address indexed borrower,
        string title
    );
    event BookReturned(
        uint256 indexed id,
        address indexed returned,
        string title
    );

    modifier validateId(uint256 _id) {
        if (_id >= books.length) {
            revert InvalidId();
        }
        _;
    }

    modifier checkIfBookIsBorrowed(uint256 _id) {
        if (borrowedBooks[msg.sender][_id]) {
            revert BookAlreadyBorrowed();
        }
        _;
    }

    modifier checkIfUserBorrowedBook(uint256 _id) {
        if (!borrowedBooks[msg.sender][_id]) {
            revert BookNotBorrowed();
        }
        _;
    }

    function addBook(
        string memory title,
        string memory author,
        uint256 copies
    ) external onlyOwner {
        uint256 id = books.length;
        books.push(Book(id, title, author, copies));
        emit BookAdded(id, title, author, copies);
    }

    function increaseCopies(
        uint256 _id,
        uint256 newCopies
    ) external onlyOwner validateId(_id) {
        Book storage book = books[_id];
        book.copies += newCopies;
        emit CopiesIncreased(_id, book.copies);
    }

    function borrowBook(
        uint256 _id
    ) external validateId(_id) checkIfBookIsBorrowed(_id) {
        Book storage book = books[_id];

        if (book.copies == 0) {
            revert InsufficientCopies();
        }

        book.copies--;
        borrowedBooks[msg.sender][book.id] = true;
        usersByBook[book.id].push(msg.sender);
        emit BookBorrowed(_id, msg.sender, book.title);
    }

    function returnBook(
        uint256 _id
    ) external validateId(_id) checkIfUserBorrowedBook(_id) {
        Book storage book = books[_id];
        book.copies++;
        borrowedBooks[msg.sender][book.id] = false;
        emit BookReturned(_id, msg.sender, book.title);
    }

    function getBook(uint256 _id) external view validateId(_id) returns (Book memory) {
        return books[_id];
    }

    function getBooksCount() external view returns (uint256) {
        return books.length;
    }
}