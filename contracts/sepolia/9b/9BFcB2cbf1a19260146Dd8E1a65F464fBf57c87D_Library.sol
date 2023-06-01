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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Library is Ownable {
    bytes32[] public bookKey;
    mapping(bytes32 => Book) public books;
    mapping(bytes32 => SingleBorrowAction[]) public bookBorrowAction;
    mapping(address => mapping (bytes32 => bool)) public clientBook;

    struct Book {
        bytes32 bookId;
        string name;
        string author;
        uint8 availableCopiesCount;
    }

    // The struct is created for better visibility of who and when borrowed the book
    struct SingleBorrowAction {
        address borrowerAddress;
        uint timeStamp;
    }

    event BookAdded(bytes32 indexed bookId, string name, string author);
    event BookReturned(bytes32 indexed bookId, address borrower);
    event BookBorrowed(bytes32 indexed bookId, address borrower);
    event BookCopiesAdded(bytes32 indexed bookId, uint8 additionalCopyCount);

    modifier _isValidBook(string memory _bookTitle, string memory _author, uint _copyCount)  {
        bytes memory modTitle = bytes(_bookTitle);
        bytes memory modAuthor = bytes(_author);
        require(_copyCount > 0 && modAuthor.length > 0 && modTitle.length > 0, "Book input data is invalid");
        _;
    }

    modifier _bookExists(string memory _bookTitle, string memory _author)  {
        bytes32 newBookKey = _generateUniqueHashId(_bookTitle, _author);
        require(bytes(books[newBookKey].name).length == 0, "Book has already been added.");
        _;
    }

    function addNewBook (string memory _bookTitle, string memory _author, uint8 _copyCount) public onlyOwner _isValidBook(_bookTitle, _author, _copyCount) _bookExists(_bookTitle, _author) {
        bytes32 newBookId = _generateUniqueHashId(_bookTitle, _author);
        Book memory newBook = Book(newBookId, _bookTitle, _author, _copyCount);
        bookKey.push(newBookId);
        books[newBookId] = newBook;

        emit BookAdded(newBookId, _bookTitle, _author);
    }

    function addCopiesToAnExistingBook (bytes32 _bookId, uint8 _additionalCopyCount) public onlyOwner {
        Book storage book = books[_bookId];
        require (book.bookId.length > 0, "Book doesn't exist");
        book.availableCopiesCount += _additionalCopyCount;

        emit BookCopiesAdded(_bookId, _additionalCopyCount);
    }

    function borrow(bytes32 _bookId) public {
        uint timestamp = block.timestamp;
        address senderAddress = msg.sender;
        Book storage bookToBorrow = books[_bookId];
        require (bookToBorrow.availableCopiesCount > 0, "No available copies at the moment");
        require (_senderIsNotABorrower(bookToBorrow.bookId), "You already borrowed this book");

        clientBook[senderAddress][_bookId] = true;
        bookBorrowAction[_bookId].push(SingleBorrowAction(senderAddress, timestamp));
        bookToBorrow.availableCopiesCount--;

        emit BookBorrowed(_bookId, senderAddress);
    }

    function returnBook (bytes32 _bookId) public {
        address senderAddress = msg.sender;
        Book storage bookToBorrow = books[_bookId];
        require(!_senderIsNotABorrower(bookToBorrow.bookId), "You have not borrowed this book yet.");

        clientBook[senderAddress][_bookId] = false;
        bookToBorrow.availableCopiesCount++;

        emit BookReturned(_bookId, senderAddress);
    }

    function getBookBorrowers(bytes32 _bookId)  public view returns (SingleBorrowAction[] memory) {
        return bookBorrowAction[_bookId];
    }

    function getAllAvailableBooks() public view returns (Book[] memory) {
        uint8 counter = 0;
        uint bookKeyArrayLength = bookKey.length;

        for (uint i = 0; i < bookKeyArrayLength ; i++) {
            bytes32 currentBookKey = bookKey[i];
            Book memory currentBook = books[currentBookKey];
            if (currentBook.availableCopiesCount > 0) {
                counter++;
            }
        }

        Book[] memory availableBooks = new Book[](counter);
        uint8 avIndex = 0;
        for (uint i = 0; i < bookKeyArrayLength ; i++) {
            bytes32 currentBookKey = bookKey[i];
            Book memory currentBook = books[currentBookKey];
            if (currentBook.availableCopiesCount > 0) {
                availableBooks[avIndex] = currentBook;
                avIndex++;
            }
        }
        return availableBooks;
    }

    function _senderIsNotABorrower(bytes32 bookKeyArg) private view returns (bool) {
        return !clientBook[msg.sender][bookKeyArg];
    }

    function _generateUniqueHashId(string memory _title, string memory _authorName) private pure returns (bytes32) {
        string memory bookKeyInput = string.concat(_title, _authorName);
        return keccak256(abi.encodePacked(bookKeyInput));
    }
}