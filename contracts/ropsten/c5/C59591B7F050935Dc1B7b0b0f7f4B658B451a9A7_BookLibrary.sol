//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BookLibrary is Ownable {
    mapping(bytes32 => Book) books; // bytes32 will be used for the book name (ID)
    mapping(address => mapping(bytes32 => uint)) public booksByCustomer; // keep every customer address, the id and the block number of each item

    struct Book {
        bytes32 bookId;
        uint32 numOfCopies;
        address[] customers;
    }

    event AddBook(bytes32 bookId, uint availableCopies);
    event OrderResult(bytes32 bookId, uint32 availableCopies, address customerAddr);

    modifier bookAvailable(string memory _bookName) {
        bytes32 bookId = keccak256(abi.encodePacked(_bookName));
        require(books[bookId].numOfCopies > 0, "Not enought copies of this book");
        _;
    }

    modifier bookNotBorrowedByUser(string memory _bookName) {
        bytes32 bookId = keccak256(abi.encodePacked(_bookName));
        require(booksByCustomer[msg.sender][bookId] == 0, "A book can be borrowed only once.");
        _;
    }

    modifier bookOwnedByUser(string memory _bookName) {
        bytes32 bookId = keccak256(abi.encodePacked(_bookName));
        require(booksByCustomer[msg.sender][bookId] > 0, "The book is not borrowed by the customer.");
        _;
    }

    // Method used to add the book only from the owner of the contract
    function addBook(string memory _bookName, uint32 _copies) public onlyOwner {
        bytes32 bookId = keccak256(abi.encodePacked(_bookName));
        books[bookId].bookId = bookId;
        books[bookId].numOfCopies += _copies; // by default the number of copies will be 0, so it is fine to increment always

        emit AddBook(bookId, books[bookId].numOfCopies);
    }

    // Method used to show the book given the book name
    function getBook(string memory _bookName) public view returns (Book memory) {
        bytes32 bookId = keccak256(abi.encodePacked(_bookName));
        return books[bookId];
    }

    // Method used to borrow a book by its id
    function borrowBook(string memory _bookName) public bookAvailable(_bookName) bookNotBorrowedByUser(_bookName) {
        bytes32 bookId = keccak256(abi.encodePacked(_bookName));
        booksByCustomer[msg.sender][bookId] = 1;
        books[bookId].customers.push(msg.sender);
        books[bookId].numOfCopies -= 1;

        emit OrderResult(bookId, books[bookId].numOfCopies, msg.sender);
    }

    // Method used to return a book by its id
    function returnBook(string memory _bookName) public bookOwnedByUser(_bookName) {
        bytes32 bookId = keccak256(abi.encodePacked(_bookName));
        booksByCustomer[msg.sender][bookId] = 0;
        deleteCustomer(bookId, msg.sender);
        books[bookId].numOfCopies += 1;

        emit OrderResult(bookId, books[bookId].numOfCopies, msg.sender);
    }

    // Method to check if the user has borrowed the book
    function isBookOwnedByCustomer(string memory _bookName) public view returns (bool) {
        bytes32 bookId = keccak256(abi.encodePacked(_bookName));
        uint numBorrowed = booksByCustomer[msg.sender][bookId];
        return numBorrowed > 0;
    }

    // Method to check if the book is available
    function isAvailable(string memory _bookName) public view returns (bool) {
        bytes32 bookId = keccak256(abi.encodePacked(_bookName));
        Book memory book = books[bookId];
        return book.numOfCopies > 0;
    }

    // Method that will pop out the customer from the books collection
    function deleteCustomer(bytes32 bookId, address custAddr) private {
        uint customerLen = books[bookId].customers.length;
        if (customerLen != 0) {
            for (uint i = 0; i < customerLen; i++) {
                if (books[bookId].customers[i] == custAddr) {
                    // copy the last customer address on the place of the one that is returning the item and delete the last address
                    books[bookId].customers[i] = books[bookId].customers[customerLen - 1]; 
                    books[bookId].customers.pop();
                    break;
                }
            }
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