pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Library is Ownable {
    struct Book {
        uint256 copies;
        string name;
    }

    Book[] allBooks;

    uint256[] bookAvailability;
    mapping(uint256 => uint256) bookAvailabilityIndex;
    mapping(uint256 => bool) bookAvailabilityExists;

    address[][] borrowersHistory;
    mapping(uint256 => mapping(address => int16)) borrowers; // -1 currentborrow, 0 never, 1 unborrowed but was borrowed

    modifier validBookId(uint256 _bookId) {
        require(allBooks.length > _bookId, "Book does not exist");
        _;
    }

    function addNewBook(string memory _name, uint256 _copies) public onlyOwner {
        allBooks.push(Book(_copies, _name));
        borrowersHistory.push(new address[](0));
        uint256 bookId = allBooks.length - 1;
        if (_copies > 0) {
            addBookAvailability(bookId);
        }
    }

    function changeNumberOfBookCopies(uint256 _bookId, uint256 _copies)
        public
        onlyOwner
        validBookId(_bookId)
    {
        allBooks[_bookId].copies = _copies;
        if (_copies > 0) {
            addBookAvailability(_bookId);
        } else if (bookAvailabilityExists[_bookId]) {
            removeBookAvailability(_bookId);
        }
    }

    function getAvailableBooks() public view returns (uint256[] memory) {
        return bookAvailability;
    }

    function borrowBook(uint256 _bookId) public validBookId(_bookId) {
        require(allBooks[_bookId].copies > 0, "No copies available");
        require(
            borrowers[_bookId][msg.sender] != -1,
            "You already borrowed this book"
        );

        if (borrowers[_bookId][msg.sender] == 0) {
            borrowersHistory[_bookId].push(msg.sender);
        }
        borrowers[_bookId][msg.sender] = -1;
        if (--allBooks[_bookId].copies == 0) {
            removeBookAvailability(_bookId);
        }
    }

    function returnBook(uint256 _bookId) public validBookId(_bookId) {
        require(
            borrowers[_bookId][msg.sender] == -1,
            "You did not borrow this book"
        );

        borrowers[_bookId][msg.sender] = 2;

        if (++allBooks[_bookId].copies == 1) {
            addBookAvailability(_bookId);
        }
    }

    function getBookBorrowers(uint256 _bookId)
        public
        view
        validBookId(_bookId)
        returns (address[] memory)
    {
        return borrowersHistory[_bookId];
    }

    function removeBookAvailability(uint256 _bookId) internal {
        bookAvailabilityExists[_bookId] = false;

        // switch values
        bookAvailability[bookAvailabilityIndex[_bookId]] = bookAvailability[
            bookAvailability.length - 1
        ];
        // switch indexes
        bookAvailabilityIndex[
            bookAvailability[bookAvailabilityIndex[_bookId]]
        ] = bookAvailabilityIndex[_bookId];

        bookAvailability.pop();
    }

    function addBookAvailability(uint256 _bookId) internal {
        if (!bookAvailabilityExists[_bookId]) {
            bookAvailability.push(_bookId);
            bookAvailabilityExists[_bookId] = true;
            bookAvailabilityIndex[_bookId] = bookAvailability.length - 1;
        }
    }
}

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