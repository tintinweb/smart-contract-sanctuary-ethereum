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

// SPDX-License-Identifier: unlicensed

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BookLibrary is Ownable {
    event BookAdded(bytes32 titleHash, uint copies);
    event BookBorrowed(bytes32 titleHash, address borrower);
    event BookReturned(bytes32 titleHash, address borrower);

    string[] public books;

    enum BorrowType {
        NeverBorrowed,
        ActiveBorrow,
        Returned
    }

    struct BookMetadata {
        uint copies;
        bool exists; // has ever been in the library
        address[] allBorrowers;
        mapping(address => BorrowType) userBorrowed;
    }

    // titleHash -> BookMetadata
    mapping(bytes32 => BookMetadata) public bookIndex;

    function addBook(string calldata title, uint copies) external onlyOwner {
        bytes32 titleHash = this.getTitleHash(title);
        BookMetadata storage bookMetadata = bookIndex[titleHash];
        if (bookMetadata.exists) {
            bookMetadata.copies += copies;
        } else {
            bookMetadata.copies = copies;
            bookMetadata.exists = true;
            books.push(title);
        }
        emit BookAdded(titleHash, copies);
    }

    function getBooksLength() external view returns (uint) {
        return books.length;
    }

    function getTitleHash(
        string calldata title
    ) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(title));
    }

    function borrowBook(bytes32 _titleHash) external {
        BookMetadata storage bookMetadata = bookIndex[_titleHash];
        require(
            bookMetadata.exists,
            "A book with such an ID isn't in the inventory"
        );

        require(bookMetadata.copies >= 1, "The book is out of copies");

        require(
            !(bookMetadata.userBorrowed[msg.sender] == BorrowType.ActiveBorrow),
            "The user has already borrowed a coppy of this book"
        );

        bookMetadata.copies--;

        if (bookMetadata.userBorrowed[msg.sender] == BorrowType.NeverBorrowed) {
            bookMetadata.allBorrowers.push(msg.sender);
        }
        bookMetadata.userBorrowed[msg.sender] = BorrowType.ActiveBorrow;

        emit BookBorrowed(_titleHash, msg.sender);
    }

    function returnBook(bytes32 _titleHash) external {
        BookMetadata storage bookMetadata = bookIndex[_titleHash];
        require(
            bookMetadata.userBorrowed[msg.sender] == BorrowType.ActiveBorrow,
            "The user isn't currently borrowing this book"
        );
        bookMetadata.userBorrowed[msg.sender] = BorrowType.Returned;
        bookMetadata.copies++;

        emit BookReturned(_titleHash, msg.sender);
    }

    function getBookBorrowersLength(
        bytes32 _titleHash
    ) external view returns (uint) {
        return bookIndex[_titleHash].allBorrowers.length;
    }

    function getBookBorrowerByIndex(
        bytes32 _titleHash,
        uint _index
    ) external view returns (address) {
        return bookIndex[_titleHash].allBorrowers[_index];
    }

    function getBorrowStatus(
        bytes32 _titleHash,
        address _addr
    ) external view returns (BorrowType) {
        return bookIndex[_titleHash].userBorrowed[_addr];
    }
}