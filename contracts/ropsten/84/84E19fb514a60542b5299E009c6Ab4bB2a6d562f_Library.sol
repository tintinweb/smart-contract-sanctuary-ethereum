// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;
pragma abicoder v2;
import "@openzeppelin/contracts/access/Ownable.sol";

contract Library is Ownable {

    struct Book {
        uint id;
        string title;
        uint totalCopies;
        uint availableCopies;
        address[] borrowersHistory;
    }

    Book[] public books;
    mapping(string => bool) public existingBooks;
    mapping(uint => mapping(address => bool)) public currentlyBorrowing;

    function addNewBook(string memory bookTitle, uint numberOfCopies) onlyOwner external {
        if (!existingBooks[bookTitle]) {
            Book memory book = Book({
                id: books.length,
                title: bookTitle, 
                totalCopies: numberOfCopies, 
                availableCopies: numberOfCopies,
                borrowersHistory: new address[](0)
            });
            books.push(book);
            existingBooks[bookTitle] = true;
        } else {
            revert("This book already exists in the library.");
        }
    }

    function addCopies(uint id, uint numberOfCopies) onlyOwner external {
        require(existingBooks[books[id].title]);
        books[id].totalCopies += numberOfCopies;
        books[id].availableCopies += numberOfCopies;
    }

    function borrowBook(uint id) external payable {
        bool isAborrower = currentlyBorrowing[id][msg.sender];
        require(!isAborrower, "You already borrow this book");
        require(books[id].availableCopies > 0, "No copies available");
        books[id].availableCopies--;
        books[id].borrowersHistory.push(msg.sender);
        currentlyBorrowing[id][msg.sender] = true;
    }

    function returnBook(uint id) external payable {
        bool isAborrower = currentlyBorrowing[id][msg.sender];
        require(isAborrower, "You have not borrowed this book");
        books[id].availableCopies++; 
        currentlyBorrowing[id][msg.sender] = false;
    }

    function getBorrowersHistory(uint id) public view returns (address[] memory) {
        return books[id].borrowersHistory;
    }

    function getBooksCount() public view returns (uint) {
        return books.length;
    }

    function checkIfCurrentlyBorrowing(uint id, address addr) public view returns (bool isRented) {
        return isRented = currentlyBorrowing[id][addr];    
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