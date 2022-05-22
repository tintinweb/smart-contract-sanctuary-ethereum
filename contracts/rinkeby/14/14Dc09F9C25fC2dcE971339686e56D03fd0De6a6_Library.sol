// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Library is Ownable {
    struct Book {
        string name;
        uint availableCopies;
        uint copies;
        address[] borrowedBy;
    }

    Book[] books;

    mapping(bytes32 => uint) booksNameToId;
    mapping(address => mapping(uint => bool)) borrowingBooks;

    // Check if book exists, if it exists add copies, if it doesn't add to library
    // Only owner can invoke addBook
    function addBook(string memory _name, uint _copies) external onlyOwner {
        uint index = booksNameToId[keccak256(abi.encodePacked(_name))];

        if (index == 0) {
            Book memory book;

            book.name = _name;
            book.availableCopies = _copies;
            book.copies = _copies;

            books.push(book);
            booksNameToId[keccak256(abi.encodePacked(_name))] = books.length;
        } else {
            books[index - 1].availableCopies += _copies;
            books[index - 1].copies += _copies;
        }
    }

    // User passes an array of ids of books they want to borrow, if a book on that list is
    // already borrowed or there aren't available copies, the transaction is reverted.
    function borrowBooks(uint[] calldata _ids) external {
        for (uint i = 0; i < _ids.length; i++) {
            require(books[_ids[i]].availableCopies > 0, "There are no available copies of a selected book");
            require(!borrowingBooks[msg.sender][_ids[i]], "User is already borrowing a copy of a selected book");
        }

        for (uint i = 0; i < _ids.length; i++) {
            borrowingBooks[msg.sender][_ids[i]] = true;
            books[_ids[i]].borrowedBy.push(msg.sender);
            books[_ids[i]].availableCopies--;
        }
    }

    // User passes an array of ids of books they want to return, if a book has been borrowed,
    // it's returned.
    function returnBooks(uint[] calldata _ids) external {
        for (uint i = 0; i < _ids.length; i++) {
            if (borrowingBooks[msg.sender][_ids[i]]) {
                books[_ids[i]].availableCopies++;
                borrowingBooks[msg.sender][_ids[i]] = false;
            }
        }
    }

    function viewAvailableBooks() external view returns (Book[] memory) {
        return books;
    }

    function viewBorrowers(uint _id) external view returns (address[] memory) {
        return books[_id].borrowedBy;
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