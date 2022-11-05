// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/access/Ownable.sol";

contract Library is Ownable {
    event NewBook(uint256 id, string name, uint256 copies);
    event CopiesAdded(uint256 id, string name, uint256 copies);
    event BookBorrowed(uint256 id, uint256 remainingCopies);
    event BookReturned(uint256 id, uint256 remainingCopies);

    struct Book {
        string name;
        uint256 copies;
    }

    // Tracks the amount of books in the library
    uint256 public booksInLibrary;

    //Mapping that helps to manage how many copies of each book are out.
    mapping(uint256 => uint256) public bookIdToCopiesOut;

    // Mapping that saves a boolean if a book id is now borrowed by an address
    mapping(address => mapping(uint256 => bool))
        public addressBookIdCopiesBorrowed;

    // This keeps the order in which the books have been borrowed
    mapping(uint256 => address[]) public borrowers;

    // This is where the book info is stored. THE INDEX OF THE BOOK IN THE ARRAY IS TAKEN AS THE BOOK ID.
    Book[] public bookArray;

    // Owner Functions

    // Adds a new book to the library
    function addNewBook(string memory _name, uint256 _copies) public onlyOwner {
        Book memory _book = Book(_name, _copies);
        bookArray.push(_book);
        booksInLibrary += 1;
        //bookIdToCopiesOut[bookArray.length-1]=0;
        emit NewBook(bookArray.length - 1, _name, _copies);
    }

    // Adds more copies to a book in library by id
    function addCopies(uint256 _id, uint256 _copies) public onlyOwner {
        bookArray[_id].copies = bookArray[_id].copies + _copies;
        emit CopiesAdded(_id, bookArray[_id].name, bookArray[_id].copies);
    }

    // View functions

    //Returns the name of a book by id
    function getName(uint256 _id) public view returns (string memory) {
        require(bookArray.length - 1 >= _id, "No book with this index");
        return bookArray[_id].name;
    }

    // Returns boolean if book is available for borrowing
    function isAvailable(uint256 _id) public view returns (bool) {
        require(bookArray.length - 1 >= _id, "No book with this index");
        return bookArray[_id].copies - bookIdToCopiesOut[_id] > 0;
    }

    // returns the amount of available copies to borrow
    function availableUnits(uint256 _id) public view returns (uint256) {
        require(bookArray.length - 1 >= _id, "No book with this index");
        return bookArray[_id].copies - bookIdToCopiesOut[_id];
    }

    // returns array of book borrowers in chronological order
    function viewBookBorrowers(uint256 _id)
        public
        view
        returns (address[] memory)
    {
        require(bookArray.length - 1 >= _id, "No book with this index");
        return borrowers[_id];
    }

    // Book handleing functions

    // Lets user borrow a book
    function borrowBook(uint256 _id) public {
        require(bookArray.length - 1 >= _id, "No book with this index");
        require(isAvailable(_id), "All copies are out");
        require(
            !addressBookIdCopiesBorrowed[msg.sender][_id],
            "You already have one of those"
        );
        //borrow book
        borrowers[_id].push(msg.sender);
        bookIdToCopiesOut[_id] = bookIdToCopiesOut[_id] + 1;
        addressBookIdCopiesBorrowed[msg.sender][_id] = true;
        emit BookBorrowed(_id, bookArray[_id].copies - bookIdToCopiesOut[_id]);
    }

    //Lets user return a book
    function returnBook(uint256 _id) public {
        require(bookArray.length - 1 >= _id, "No book with this index");
        require(
            addressBookIdCopiesBorrowed[msg.sender][_id],
            "You dont have this book"
        );
        //return book
        bookIdToCopiesOut[_id] = bookIdToCopiesOut[_id] - 1;
        addressBookIdCopiesBorrowed[msg.sender][_id] = false;
        emit BookBorrowed(_id, bookArray[_id].copies - bookIdToCopiesOut[_id]);
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