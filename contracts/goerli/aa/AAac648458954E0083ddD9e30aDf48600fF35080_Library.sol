// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Library is Ownable {
    struct Book {
        string name;
        uint8 copies;
        address[] borrowedBy;
    }

    string[] private bookIds;

    mapping(string => Book) private bookIdToBook;
    /// @dev keeps track of the books that has available copies to borrow
    mapping(string => bool) private availableBooks;
    /// @dev keeps track of the books that are registered in the library
    mapping(string => bool) private registeredBooks;
    /// @dev keeps track of the block number of the books borrowed by specific user
    mapping(string => mapping(address => uint))
        private bookBorrowedAtBlockNumber;

    /// @dev emits when book has been added
    event BookAdded(Book book);
    /// @dev emits when already registered book has new copies added
    event BookCopiesAdded(Book book, uint8 copies);
    /// @dev emits when book was borrowed by user
    event BookBorrowed(Book book, address user);
    /// @dev emits when book was returned by user
    event BookReturned(Book book, address user);

    /**
        @dev Add new book, or increase the availabe copies it it exist in the library
    */
    function addBook(string memory _bookId, uint8 _copies) external onlyOwner {
        require(
            _copies > 0,
            "The book should have at least one copy to be added!"
        );

        if (registeredBooks[_bookId] == false) {
            registeredBooks[_bookId] = true;
            bookIdToBook[_bookId] = Book({
                name: _bookId,
                copies: _copies,
                borrowedBy: new address[](0)
            });
            bookIds.push(_bookId);

            emit BookAdded(bookIdToBook[_bookId]);
        } else {
            bookIdToBook[_bookId].copies =
                bookIdToBook[_bookId].copies +
                _copies;

            emit BookCopiesAdded(bookIdToBook[_bookId], _copies);
        }
        _adjustBookAvailability(_bookId);
    }

    /**
        @dev Borrow book if it has available copies and is not borrowed by the user at the moment
    */
    function borrowBook(string memory _bookId) external {
        Book storage _book = bookIdToBook[_bookId];

        require(
            _book.copies > 0,
            "The book has no available copies at the moment!"
        );
        require(
            bookBorrowedAtBlockNumber[_bookId][msg.sender] == 0,
            "The book is currently borrowed by this user!"
        );

        _book.borrowedBy.push(msg.sender);
        _book.copies--;
        bookBorrowedAtBlockNumber[_bookId][msg.sender] = block.number;
        _adjustBookAvailability(_bookId);

        emit BookBorrowed(bookIdToBook[_bookId], msg.sender);
    }

    /**
        @dev Return book, if was borrowed by the user and the it is returned on time (less than 100 blocks away)
    */
    function returnBook(string memory _bookId) external {
        Book storage _book = bookIdToBook[_bookId];

        require(
            bookBorrowedAtBlockNumber[_bookId][msg.sender] != 0,
            "The book is not borrowed by this user!"
        );
        require(
            block.number - bookBorrowedAtBlockNumber[_bookId][msg.sender] < 100,
            "The book was not returned on time!"
        );

        bookBorrowedAtBlockNumber[_bookId][msg.sender] = 0;
        _book.copies++;
        _adjustBookAvailability(_bookId);

        emit BookReturned(bookIdToBook[_bookId], msg.sender);
    }

    /**
        @dev Returns all books registered in the Library.
    */
    function getAllBooks() external view returns (string[] memory) {
        return bookIds;
    }

    /**
        @dev Returns all book registered in the Library.
    */
    function isBookAvailable(string memory _bookId)
        external
        view
        returns (bool)
    {
        return availableBooks[_bookId];
    }

    /**
        @dev Returns array of addresses that has evere borrowed the book by the passed id.
    */
    function getBorrowedAddressesForBook(string memory _bookId)
        external
        view
        returns (address[] memory)
    {
        return bookIdToBook[_bookId].borrowedBy;
    }

    /**
        @dev Adjust the mapping that keeps track of the books that has available copies to borrow.
    */
    function _adjustBookAvailability(string memory _bookId) private {
        if (
            availableBooks[_bookId] == false && bookIdToBook[_bookId].copies > 0
        ) {
            availableBooks[_bookId] = true;
        } else if (
            availableBooks[_bookId] == true && bookIdToBook[_bookId].copies == 0
        ) {
            availableBooks[_bookId] = false;
        }
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