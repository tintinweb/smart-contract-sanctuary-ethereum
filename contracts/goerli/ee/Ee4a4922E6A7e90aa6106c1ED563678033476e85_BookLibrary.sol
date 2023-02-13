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

import "@openzeppelin/contracts/access/Ownable.sol";

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

contract BookLibrary is Ownable {
    uint256 public counter;

    struct BookInfo {
        string bookName;
        address[] borrowers;
        uint256 numberOfCopies;
    }
    // id => Book Info
    mapping(uint256 => BookInfo) public books;

    // books that have a positive number of copies
    uint256[] public availableBooks;
    // id => index in array `availableBooks`
    mapping(uint256 => uint256) public ixAvailableBooks;

    //address => id => has borrowed a book before or not
    mapping(address => mapping(uint256 => bool)) public hasBorrowedBook;

    //address => id => did borrow a book or not
    mapping(address => mapping(uint256 => bool)) public didBorrowBook;

    function addBook(
        string memory bookName,
        uint256 numberOfCopies
    ) external onlyOwner {
        require(
            numberOfCopies > 0,
            "Add a book with number of copies above zero"
        );
        books[counter].bookName = bookName;
        books[counter].numberOfCopies = numberOfCopies;

        _includeIdInAvailableBooks(counter);

        _increaseCounter();
    }

    function borrowBookById(uint256 id) external {
        BookInfo storage book = books[id];
        require(
            !didBorrowBook[msg.sender][id],
            "Cannot borrow the same book twice"
        );
        require(book.numberOfCopies > 0, "No book copy available");

        didBorrowBook[msg.sender][id] = true;
        book.numberOfCopies--;

        if (!hasBorrowedBook[msg.sender][id]) {
            book.borrowers.push(msg.sender);
            hasBorrowedBook[msg.sender][id] = true;
        }

        if (book.numberOfCopies == 0) {
            _removeIdFromAvailableBooks(id);
        }
    }

    function returnBookById(uint256 id) external {
        BookInfo storage book = books[id];
        require(
            didBorrowBook[msg.sender][id],
            "Caller did not borrow this book"
        );
        didBorrowBook[msg.sender][id] = false;
        book.numberOfCopies++;

        if (book.numberOfCopies == 1) {
            _includeIdInAvailableBooks(id);
        }
    }

    function getAvailableBooks()
        external
        view
        returns (BookInfo[] memory listOfBooks)
    {
        uint256 length = availableBooks.length;
        listOfBooks = new BookInfo[](length);

        for (uint256 i; i < length; i++) {
            listOfBooks[i] = books[availableBooks[i]];
        }
    }

    function getBorrowersOfBookById(
        uint256 id
    ) external view returns (address[] memory) {
        return books[id].borrowers;
    }

    /////////////////////////////////////////////////////
    ////////////        Helpers              ////////////
    /////////////////////////////////////////////////////

    function _removeIdFromAvailableBooks(uint256 id) internal {
        uint256 ixToRemove = ixAvailableBooks[id];
        uint256 lastId = availableBooks[availableBooks.length - 1];
        availableBooks[ixToRemove] = lastId;
        availableBooks.pop();
        ixAvailableBooks[lastId] = ixToRemove;
    }

    function _includeIdInAvailableBooks(uint256 id) internal {
        availableBooks.push(id);
        ixAvailableBooks[id] = availableBooks.length - 1;
    }

    function _increaseCounter() internal {
        counter++;
    }
}