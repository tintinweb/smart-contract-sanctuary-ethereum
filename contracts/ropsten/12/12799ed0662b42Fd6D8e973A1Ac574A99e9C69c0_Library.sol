// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Library is Ownable {
    mapping(bytes32 => Book) public books;
    bytes32[] public bookIds;

    event BookAdded(bytes32 id, string name, uint8 copies);
    event BookUpdated(bytes32 id, uint8 newQuantity);
    event BookTaken(bytes32 bookId, address userAddress);
    event BookReturned(bytes32 bookId, address userAddress);

    enum BorrowStatus {
        New,
        Holding,
        Taken
    }

    struct Book {
        string name;
        uint8 copies;
        mapping(address => BorrowStatus) borrowStatus;
        address[] borrowers;
    }

    modifier bookExists(bytes32 id) {
        bytes memory bookName = bytes(books[id].name);
        require(bookName.length != 0, "This book does not exist!");
        _;
    }

    modifier haveAvailableCopies(bytes32 id) {
        require(
            books[id].copies > 0,
            "There is no available copies right now!"
        );
        _;
    }

    modifier bookIsNotTaken(bytes32 id) {
        require(
            books[id].borrowStatus[msg.sender] != BorrowStatus.Holding,
            "This book has already been taken from you!"
        );
        _;
    }

    modifier bookIsTaken(bytes32 id) {
        require(
            books[id].borrowStatus[msg.sender] == BorrowStatus.Holding,
            "You do not have such a book!"
        );
        _;
    }

    function hash(string memory _string) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_string));
    }

    function addBook(string memory name, uint8 copies) public onlyOwner {
        bytes32 bookId = hash(name);
        bytes memory bookName = bytes(books[bookId].name);
        require(bookName.length == 0, "The book has been already added!");
        Book storage myBook = books[bookId];
        myBook.name = name;
        myBook.copies = copies;
        bookIds.push(bookId);
        emit BookAdded(bookId, name, copies);
    }

    function updateBook(bytes32 id, uint8 copies)
        public
        onlyOwner
        bookExists(id)
    {
        books[id].copies += copies;
        emit BookUpdated(id, copies);
    }

    function getBook(bytes32 id)
        public
        bookExists(id)
        haveAvailableCopies(id)
        bookIsNotTaken(id)
    {
        Book storage book = books[id];
        book.copies -= 1;
        if (book.borrowStatus[msg.sender] == BorrowStatus.New) {
            book.borrowers.push(msg.sender);
        }
        book.borrowStatus[msg.sender] = BorrowStatus.Holding;
        emit BookTaken(id, msg.sender);
    }

    function returnBook(bytes32 id) public bookExists(id) bookIsTaken(id) {
        Book storage book = books[id];
        book.copies += 1;
        book.borrowStatus[msg.sender] = BorrowStatus.Taken;
        emit BookReturned(id, msg.sender);
    }

    function getAllBooksLength() public view returns (uint256) {
        return bookIds.length;
    }

    function getAddressesByBookId(bytes32 id)
        public
        view
        bookExists(id)
        returns (address[] memory)
    {
        return books[id].borrowers;
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