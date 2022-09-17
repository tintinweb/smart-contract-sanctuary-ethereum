pragma solidity 0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BookLibrary is Ownable {

    event LogStateBookAdded(uint bookId, string title);
    event LogStateBookBorrowed(uint bookId, address person);
    event LogStateBookReturned(uint bookId, address person);

    struct Book {
        string title;
        uint8 bookCopiesCount;
    }

    uint availableBookCount = 0;
    Book[] books;
    mapping (bytes32 => bool) PersonBookToIsBookBorrowed;
    mapping (uint => address[]) BookToPersons;

    function addBook(string calldata _title, uint8 _bookCopiesCount) external onlyOwner {
        books.push(Book(_title, _bookCopiesCount));
        availableBookCount++;

        uint id = books.length - 1;
        emit LogStateBookAdded(id, books[id].title);
    }

    function borrowBook(uint _bookId) external bookExists(_bookId) haveAvailableBooks {
        require(books[_bookId].bookCopiesCount > 0, "No copies left.");
        bytes32 personBook = keccak256(abi.encodePacked(msg.sender, abi.encodePacked(_bookId)));
        require(PersonBookToIsBookBorrowed[personBook] == false, "You already borrowed this book.");
        
        PersonBookToIsBookBorrowed[personBook] = true;
        books[_bookId].bookCopiesCount--;
        BookToPersons[_bookId].push(msg.sender);

        if (books[_bookId].bookCopiesCount == 0) {
            availableBookCount--;
        }

        emit LogStateBookBorrowed(_bookId, msg.sender);
    }

    function returnBook(uint _bookId) external bookExists(_bookId) {
        bytes32 personBook = keccak256(abi.encodePacked(msg.sender, abi.encodePacked(_bookId)));
        require(PersonBookToIsBookBorrowed[personBook] == true, "You didn't borrow this book.");

        PersonBookToIsBookBorrowed[personBook] = false;

        if (books[_bookId].bookCopiesCount == 0) {
            availableBookCount++;
        }

        books[_bookId].bookCopiesCount++;

        emit LogStateBookReturned(_bookId, msg.sender);
    }

    function getBookRecipients(uint _bookId) external view returns(address[] memory)  {
        return BookToPersons[_bookId];
    }

    function getAvailableBookIds() external haveAvailableBooks view returns(uint[] memory)  {
        uint[] memory availableBookIds = new uint[](availableBookCount);

        uint counter = 0;
        for (uint bookId = 0; bookId < books.length; bookId++) {
            if (books[bookId].bookCopiesCount > 0) {
                availableBookIds[counter] = bookId;
                counter++;
            }
        }

        return availableBookIds;
    }

    modifier bookExists(uint _bookId) {
        require(_bookId < books.length, "The book is not found.");
        _;
    }

    modifier haveAvailableBooks() {
        require(availableBookCount > 0, "No books available.");
        _;
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