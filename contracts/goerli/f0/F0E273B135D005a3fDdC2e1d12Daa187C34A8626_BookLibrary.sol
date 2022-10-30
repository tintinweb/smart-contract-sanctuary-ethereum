// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BookLibrary is Ownable {
    uint256 private bookCounter = 0;
    Book[] private books;
    mapping(address => string[]) private currentlyBorrowedBooks;
    mapping(string => address[]) private bookBorrowingHistory;

    struct Book {
        string id;
        uint256 copies;
    }

    function addNewBook(string memory _id, uint256 _copies) external onlyOwner {
        validateBookIdUnique(_id);
        books.push(Book(_id, _copies));
        bookCounter++;
    }

    function listAvailableBooks() external view returns (string[] memory) {
        string[] memory result = new string[](bookCounter);
        for (uint256 i = 0; i < bookCounter; i++) {
            Book memory book = books[i];
            if (book.copies > 0) {
                result[i] = book.id;
            }
        }
        return result;
    }

    function borrowBook(string memory _id) external {
        Book storage borrowedBook = getBook(_id);
        validateBookAvailableForBorrowing(borrowedBook);
        string[] storage currentlyBorrowedByUser = currentlyBorrowedBooks[
        msg.sender
        ];
        validateBookNotAlreadyBorrowed(borrowedBook, currentlyBorrowedByUser);
        currentlyBorrowedByUser.push(borrowedBook.id);
        borrowedBook.copies--;
        address[] storage bookHistory = bookBorrowingHistory[_id];
        bookHistory.push(msg.sender);
    }

    function returnBook(string memory _id) external {
        Book storage returnedBook = getBook(_id);
        string[] storage currentlyBorrowedByUser = currentlyBorrowedBooks[
        msg.sender
        ];
        uint256 bookIndex = determineBookIndex(
            returnedBook,
            currentlyBorrowedByUser
        );
        delete currentlyBorrowedByUser[bookIndex];
        returnedBook.copies++;
    }

    function listBookBorrowingHistory(string memory _id)
    external
    view
    returns (address[] memory)
    {
        return bookBorrowingHistory[_id];
    }

    // ========== \/ PRIVATE \/ ========== \\

    function validateBookIdUnique(string memory _id) private view {
        for (uint256 i = 0; i < bookCounter; i++) {
            require(
                !compareStrings(books[i].id, _id),
                "The book id is not unique"
            );
        }
    }

    function compareStrings(string memory first, string memory second)
    private
    pure
    returns (bool)
    {
        return keccak256(bytes(first)) == keccak256(bytes(second));
    }

    function getBook(string memory _id) private view returns (Book storage) {
        for (uint256 i = 0; i < bookCounter; i++) {
            Book storage book = books[i];
            if (compareStrings(book.id, _id)) {
                return book;
            }
        }
        revert("Could not find book id");
    }

    function validateBookAvailableForBorrowing(Book memory book) private pure {
        require(book.copies > 0, "There are no available copies of given book");
    }

    function validateBookNotAlreadyBorrowed(
        Book memory book,
        string[] memory borrowedBookIds
    ) private pure {
        for (uint256 i = 0; i < borrowedBookIds.length; i++) {
            require(
                !(compareStrings(book.id, borrowedBookIds[i])),
                "A copy of given book is already borrowed"
            );
        }
    }

    function determineBookIndex(
        Book memory searchedBook,
        string[] memory borrowedBookIds
    ) private pure returns (uint256) {
        for (uint256 i = 0; i < borrowedBookIds.length; i++) {
            if (compareStrings(searchedBook.id, borrowedBookIds[i])) {
                return i;
            }
        }
        revert("Book cannot be returned because it was not borrowed");
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