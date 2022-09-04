// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

//import "./Ownable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Library is Ownable {
    
    event NewBook(uint bookId, string bookName, uint8 numberOfCopies);
    
    mapping (uint => address) bookToUser;
    mapping (uint => address[]) bookToAddresses;
    
    struct Book {
        string name;
        uint8 numberOfCopies;
    }
    
    Book[] public books;
    
    function addBook(string calldata _bookName, uint8 _numberOfCopies) internal onlyOwner {
        books.push(Book(_bookName, _numberOfCopies));
        uint id = books.length;
        emit NewBook(id, _bookName, _numberOfCopies);
    }
    
    function getAvailableBooks() external view returns(uint[] memory) {
        uint[] memory result = new uint[](books.length);
        uint counter = 0;
        
        for (uint i = 0; i < books.length; i++) {
            result[counter] = i;
            counter++;
        }
        return result;
    }
    
    modifier atLeastOneCopy(uint _bookId) {
        require(books[_bookId].numberOfCopies > 0);
        _;
    }
    
    modifier onlyBorrower(uint _bookId) {
        require(msg.sender == bookToUser[_bookId]);
        _;
    }
    
    function borrowBook(uint _bookId) external atLeastOneCopy(_bookId) {
        bookToUser[_bookId] = msg.sender;
        bookToAddresses[_bookId].push(msg.sender);
        books[_bookId].numberOfCopies--;
    }
    
    function returnBook(uint _bookId) external onlyBorrower(_bookId) {
        //TODO remove the book from the s
        books[_bookId].numberOfCopies++;
    }
    
    function viewAllPeopleBorrowedABook(uint _bookId) public view returns(address[] memory) {
        return bookToAddresses[_bookId];
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