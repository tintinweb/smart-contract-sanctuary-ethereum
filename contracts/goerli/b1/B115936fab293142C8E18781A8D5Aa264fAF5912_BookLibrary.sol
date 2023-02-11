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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
pragma abicoder v2;
import "@openzeppelin/contracts/access/Ownable.sol";

contract BookLibrary is Ownable{

    struct Book{
        string name;
        uint copies;
        address[] bookBorrowedAdresses;
    }

    bytes32[] public bookKeys;

    mapping(bytes32 => Book) public books;
    mapping(address => mapping(bytes32 => bool)) private borrowedBook;

    event AdjustCopies(string _bookName, uint _copies);
    event AddedBook(string _bookName, uint _copies);
    event BorrowedBook(string _bookName, address _address);
    event ReturnedBook(string _bookName, address _address);

    modifier doesBookExists(string memory _bookName){
        require(bytes(books[keccak256(abi.encodePacked(_bookName))].name).length != 0 ,"This book doesn't exists");
        _;
    }

    modifier isBookValid(string memory _bookName, uint _copies){
        bytes memory tempBookName = bytes(_bookName);
        require(tempBookName.length > 0 && _copies > 0, "Book data is not valid");
        _;
    }

    // Add new book, if the book is already in the library we are adding only the copies
    function addBook(string memory _bookName, uint _copies) public onlyOwner isBookValid(_bookName, _copies){
        address[] memory emptyAddressList;
        bytes32 bookNameBytes = bytes32(keccak256(abi.encodePacked(_bookName)));

        if(bytes(books[bookNameBytes].name).length > 0){
            books[bookNameBytes].copies += _copies;
            emit AdjustCopies(_bookName,books[bookNameBytes].copies);
        }
        else{
            books[bookNameBytes] = Book(_bookName,_copies, emptyAddressList);
            bookKeys.push(bookNameBytes);
            emit AddedBook(_bookName, _copies);
        }

    }

    // Borrow book only if it's available
    function borrowBook(string memory _bookName) public doesBookExists(_bookName){
        bytes32 bookName = bytes32(keccak256(abi.encodePacked(_bookName)));

        require(books[bookName].copies > 0, "At the moment, the library doesn't have copy of this book.");
        require(borrowedBook[msg.sender][bookName] == false, "This address already borrowed this book.");
        
        borrowedBook[msg.sender][bookName] = true;
        books[bookName].copies--;
        books[bookName].bookBorrowedAdresses.push(msg.sender);

        emit BorrowedBook(_bookName, msg.sender);
    }

    // Return book
    function returnBook(string calldata _bookName) public {
        bytes32 bookName = bytes32(keccak256(abi.encodePacked(_bookName)));

        require(borrowedBook[msg.sender][bookName],"You don't have this book");
        
        borrowedBook[msg.sender][bookName] = false;
        books[bookName].copies++;

        emit ReturnedBook(_bookName,msg.sender);
    }

    // Helpers
    function getNumberOfBooks() public view returns (uint _numberOfBooks){
        return bookKeys.length;
    }
}