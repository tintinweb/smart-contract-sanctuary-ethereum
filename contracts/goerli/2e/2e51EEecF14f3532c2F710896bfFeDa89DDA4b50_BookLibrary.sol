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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
@dev Import OpenZeppelin's the Ownable contract.
*/
import "@openzeppelin/contracts/access/Ownable.sol";

/**
	@title BookLibrary
	@notice This contract implements a library where books can be added, borrowed, and returned. It allows client to get a book by id or title and it also allows 
    to view the whole list of borrowers for  a given  book
	@dev  It inherits from the Ownable contract to ensure that only the owner can add books.
	@dev Assumption: it is not a requirement that the list of borrowers of a given book doesn't repeat borrower addresses. i.e. if an address borrows a book multiple times the address will be added to the borrowers array multiple times
	@dev Removing books from the library is not a requirement
	@author Baltasar Romero
*/
contract BookLibrary is Ownable {
    ///	@dev Struct that defines the book information. In includes the following data: the Title of the book, the number of copies currently available in the library, Array with addresses of the borrowers (notice this won't be unique).
    struct Book {
        string title;
        uint256 copies;
        address[] borrowers;
    }

    ///@dev Mapping of books in the library. The key is the book title in bytes32 as it is more gas efficient.
    mapping(bytes32 => Book) public books;

    /// @dev Contains all the different book keys (based on their title) this can be used by clients to get all the keys and then retrieve all the books
    bytes32[] public bookKeys;

    /// @dev Mapping of books currently borrowed to the borrowers. The first key is the address of the borrower, the second key is the book key (title in bytes32) and the value is a boolean indicating whether the address is currently borrowing the book
    mapping(address => mapping(bytes32 => bool)) public borrowedBook;

    /// @dev This is an event that will be emitted everytime a book title is added to the library for the first time. 
    event NewBookAdded(string title);
    /// @dev Event to be emmited when new copies of an already existent book are added to the library
    event BookCopyAdded(string title, uint256 copies);
    /// @dev Emmited whenever a copy of a given book is emmited
    event BookBorrowed(string title, address borrower, uint256 availableCopies);
    /// @dev Emmited when a copy of a book is returned to the library
    event BookReturned(string title, address borrower, uint256 availableCopies);

    /**
     * @dev this is used to validate that a book that is being added to the library has a valid title. THe title should not be empty     .
     * @param   _title  the title of the book that we want to validate
     */
    modifier validBookTitle(string memory _title) {
        bytes memory tempTitle = bytes(_title);
        require(tempTitle.length > 0, "Title is not valid");
        _;
    }

    /**
     * @notice  checks if a book with the given title is already present in the library
     * @dev     converts the string parameter to bytes, looks in the mapping and does the comparison by checking the title's bytes length
     * @param   _title  the title of the book we are looking for
     * @return exists a boolean value indicating if the book is present in the library
     * @return bookKey the title of the book in bytes32 format that can be used as key for lookup
     * @return requestedBook the struct with the data associated with the requeted book. If the book is not found all values will be set to its default
     */
    function findBook(string memory _title)
        private
        view
        returns (
            bool exists,
            bytes32 bookKey,
            Book storage requestedBook
        )
    {
        bookKey = keccak256(abi.encodePacked(_title));
        requestedBook = books[bookKey];

        exists = bytes(requestedBook.title).length != 0;
    }

    /// @dev Function to add a copy of a given book to the library. Only the owner can add a book. The title cannot be empty. Only the owner of the contract can invoke this function.
    /// @param _title Title of the book.
    function addBook(string memory _title)
        public
        onlyOwner
        validBookTitle(_title)
    {
        (bool exists, bytes32 bookKey, Book storage book) = findBook(_title);

        // if book does not exist we should insert it
        // if it already exist we should just increase the number of copies
        if (!exists) {
            Book memory newBook = Book({
                title: _title,
                copies: 1,
                borrowers: new address[](0)
            });
            books[bookKey] = newBook;
            bookKeys.push(bookKey);
        } else {
            book.copies++;
        }

        // Emit events
        if (!exists) {
            emit NewBookAdded(_title);
        } else {
            emit BookCopyAdded(_title, book.copies);
        }
    }

    ///	@dev Allows a user to borrow a book from the library. Validates that the requested title is not empty.
    ///	@param _title The title of the book to be borrowed.
    ///	@dev returns the error "The requested book does not exist." If the book ID is not valid.
    ///	@dev returns the error "There are no more available copies of this book." If all copies of the book have been borrowed.
    ///	@dev returns the error "You have already borrowed this book." If the user has already borrowed this book.
    function borrowBook(string memory _title) public validBookTitle(_title) {
        (bool exists, bytes32 bookKey, Book storage book) = findBook(_title);

        require(exists, "The requested book does not exist.");

        require(
            book.copies > 0,
            "There are no more available copies of this book."
        );

        require(
            !borrowedBook[msg.sender][bookKey],
            "You have already borrowed this book."
        );

        // mark book as borrowed by the borrower
        borrowedBook[msg.sender][bookKey] = true;
        // decrease number of copies to indicate availability
        book.copies--;
        // Given there's no requirement for uniqueness we don't need to check if the address is already added to the array
        book.borrowers.push(msg.sender);

        emit BookBorrowed(_title, msg.sender, book.copies);
    }

    /// @dev Allows a user to return a book they have borrowed from the library.
    /// @param _title The title of the book to be returned. It cannot be empty.
    /// @notice retuurns the error:  "The requested book does not exist." If the book ID is not valid.
    /// @notice retuurns the error: "You are not borrowing this book." If the user is not currently borrowing the book.
    function returnBook(string memory _title) public validBookTitle(_title) {
        (bool exists, bytes32 bookKey, Book storage book) = findBook(_title);

        require(exists, "The requested book does not exist.");

        require(
            borrowedBook[msg.sender][bookKey],
            "You have not borrowed this book."
        );

        // Book is no longer borrowed by this address
        borrowedBook[msg.sender][bookKey] = false;
        // increase number of copies to update availability
        book.copies++;

        emit BookReturned(_title, msg.sender, book.copies);
    }

    /// @dev Allows users to retrieve the borrowers of a given book
    /// @param _title The title of the book.
    /// @notice returns An array of addresses representing the borrowers of the book.
    /// @notice returns the error: "The requested book does not exist." If the book ID is not valid.
    function getBorrowers(string memory _title)
        public
        view
        validBookTitle(_title)
        returns (address[] memory borrowers) 
    {
        (bool exists, , Book storage book) = findBook(_title);

        require(exists, "The requested book does not exist.");
        return book.borrowers;
    }

    /**
     * @notice  returns the length of the bookKeys array which represents the number of unique books (different book titles) available in the library
     * @dev     this number should be used to obtain all keys from the bookKeys array and then retrieve el the books from the books mapping
     */
    function getNumberOfBooks() external view returns (uint256 _numberOfBooks) {
        return bookKeys.length;
    }
	
    /**
     * @notice  gets the data associated to a book by its title
     * @dev     validates that the title is not an empty string, converts the title to bytes32 to get the book key
     * @param   _title  the title of the requested book
     * @return  requestedBook  a struct with the title of the book, number of copies and an array of borrowers
     */
    function getBookByTitle(string memory _title)
        external
        view
        validBookTitle(_title)
        returns (
            Book memory requestedBook
        )
    {
        bytes32 bookKey = keccak256(abi.encodePacked(_title));
        requestedBook = books[bookKey];
    }

	 /**
     * @notice  gets the data associated to a book by its title
     * @dev     validates that the title is not an empty string, converts the title to bytes32 to get the book key
     * @param   _bookKey the key of the book to be returned in bytes32 format
     * @return  requestedBook  a struct with the title of the book, number of copies and an array of borrowers
     */
    function getBookByKey(bytes32  _bookKey)
        external
        view
        returns (
            Book memory requestedBook
        )
    {
        requestedBook = books[_bookKey];
    }
}