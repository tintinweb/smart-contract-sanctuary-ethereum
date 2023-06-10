// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BooksLibrary is Ownable {
    struct Book {
        string author;
        string title;
        uint8 copies;
        address[] bookBorrowedAddresses;
    }


    bytes32[] public bookId;
    uint8 private availableBooksCount;
    mapping(bytes32 => bool) public availableBooks;
    mapping(bytes32 => Book) public books;
    mapping(address => mapping(bytes32 => bool)) public borrowedBook;
    

    event LogAddedBook(bytes32 id, string author, string title, uint8 copies);
    event LogBorrowedBook(address borrowerAddress, bytes32 bookId);
    event LogReturnedBook(address returnerAddress, bytes32 bookId);


    modifier validBookData(string memory _author, string memory _title, uint8 _copies) {
        bytes memory tempAuthor = bytes(_author);
        bytes memory tempTitle = bytes(_title);

        require(tempAuthor.length > 0 && tempTitle.length > 0 && _copies > 0, "Book data is not valid!");
        _;
    }
    modifier bookExists(bytes32 _bookId) {
        require(libraryContainsBook(_bookId), "Book with such Id does not exist");
        _;
    }


    function addBook(string memory _author, string memory _title, uint8 _copies) public onlyOwner validBookData(_author, _title, _copies) {
        bytes32 _bookId = keccak256(abi.encodePacked(_title));

        if(!libraryContainsBook(_bookId)) {
            address[] memory borrowed;
            books[_bookId] = Book(_author, _title, 0, borrowed);
            bookId.push(_bookId);
        }

        books[_bookId].copies += _copies;
        availableBooks[_bookId] = true;
        availableBooksCount++;

        emit LogAddedBook(_bookId, _author, _title, _copies);
    }

    function borrowBook(bytes32 _bookId) bookExists(_bookId)  public {
        require(!(borrowedBook[msg.sender][_bookId]), "You have already borrowed this book!");
        require(availableBooks[_bookId], "There are no available copies of this book right now!");
       
        Book storage book = books[_bookId];
        book.bookBorrowedAddresses.push(msg.sender);
        book.copies--;

        if (book.copies == 0) {
            availableBooks[_bookId] = false;
            availableBooksCount--;
        }     

        borrowedBook[msg.sender][_bookId] = true;

        emit LogBorrowedBook(msg.sender, _bookId);
    }

    function returnBook(bytes32 _bookId) bookExists(_bookId) public {
        require(borrowedBook[msg.sender][_bookId], "You cannot return a book that you have not borrowed!");
        
        books[_bookId].copies++;
        borrowedBook[msg.sender][_bookId] = false;
        
        if(!availableBooks[_bookId]) {
            availableBooks[_bookId] = true;
            availableBooksCount++;
        }

        emit LogReturnedBook(msg.sender, _bookId);
    }

    function getAllAddressesThatBorrowedBook(bytes32 _bookId) bookExists(_bookId) public view returns(address[] memory) {
        return books[_bookId].bookBorrowedAddresses;
    }

    function getAllAvailableBooks() public view returns(bytes32[] memory) {
        bytes32[] memory _availableBooks = new bytes32[](availableBooksCount);
        
        uint8 counter = 0;
        for(uint8 i = 0; i < bookId.length; i++) {
            if(availableBooks[bookId[i]]) {
                _availableBooks[counter++] = bookId[i];
            }
        }

        return _availableBooks;
    }

    function libraryContainsBook(bytes32 _bookId) private view returns(bool) {
        return (keccak256(abi.encodePacked(books[_bookId].title)) != keccak256(abi.encodePacked("")));
    }
}

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