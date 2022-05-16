// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BookLibrary is Ownable {
    struct Book {
        string name;
        uint256 copies;
        uint256 borrowed;
        address[] allBorrowers;
    }
    Book[] private books;
    mapping(string => uint256) private bookNamesToIds;

    mapping(address => mapping(uint256 => uint256)) private borrowerToBookIdsToStatus;
    uint256 private constant BORROWED = 1; // This constant may serve as Status in borrowerToBookIdsToStatus
    uint256 private constant RETURNED = 2; // This constant may serve as Status in borrowerToBookIdsToStatus

    // This is a struct used to return info about available books
    struct AvailableBook {
        uint256 id;
        string book;
    }

    function _isNewBook(string calldata _name) private view returns (bool) {
        bool newBook = false;
        if (bookNamesToIds[_name] == 0) {
            // If it doesn't exist in a mapping, it has the default value of zero
            newBook = true;
            // But that causes problem when the key really equals to zero, so we need to verify such key by name
            if (books.length > 0) {
                if (
                    keccak256(abi.encodePacked(books[0].name)) ==
                    keccak256(abi.encodePacked(_name))
                ) {
                    newBook = false;
                }
            }
        }
        return newBook;
    }

    function addBook(string calldata _name, uint256 _copies) public onlyOwner {
        require(_copies > 0, "Please add at least one copy.");

        if (_isNewBook(_name)) {
            // If such book doesn't exist yet, we will add it with all info
            Book memory newBook = Book(_name, _copies, 0, new address[](0));
            books.push(newBook);
            bookNamesToIds[_name] = books.length - 1;
        } else {
            // If such book already exists in the libary, we will just increase the number of copies
            books[bookNamesToIds[_name]].copies =
                books[bookNamesToIds[_name]].copies +
                _copies;
        }
    }

    function getAvailableBooks() public view returns (AvailableBook[] memory) {
        // We will first find out the number of available book titles
        // This is due to the fact, that memory arryas have to be fixed-sized
        uint256 counter = 0;
        for (uint256 i = 0; i < books.length; i++) {
            if (books[i].copies - books[i].borrowed > 0) {
                counter++;
            }
        }

        // Then we will fetch the data of the available books
        AvailableBook[] memory availableBooks = new AvailableBook[](counter);
        counter = 0;
        for (uint256 i = 0; i < books.length; i++) {
            if (books[i].copies - books[i].borrowed > 0) {
                availableBooks[counter] = AvailableBook(
                    bookNamesToIds[books[i].name],
                    books[i].name
                );
                counter++;
            }
        }
        return availableBooks;
    }

    function borrowBook(uint256 _id) public bookMustExist(_id) {
        require(
            borrowerToBookIdsToStatus[msg.sender][_id] != BORROWED,
            "Please return the book first."
        );
        require(
            books[_id].copies - books[_id].borrowed > 0,
            "No available copies."
        );

        // Add to allBorrowers if it's the first time user borrows this book
        if (borrowerToBookIdsToStatus[msg.sender][_id] != RETURNED) {
            books[_id].allBorrowers.push(msg.sender);
        }

        // Borrow this book
        borrowerToBookIdsToStatus[msg.sender][_id] = BORROWED;
        books[_id].borrowed = books[_id].borrowed + 1;
    }

    function returnBook(uint256 _id) public bookMustExist(_id) {
        require(
            borrowerToBookIdsToStatus[msg.sender][_id] == BORROWED,
            "Sender doesn't have this book."
        );
        borrowerToBookIdsToStatus[msg.sender][_id] = RETURNED;
        books[_id].borrowed = books[_id].borrowed - 1;
    }

    function getAllBorrowers(uint256 _id)
        public
        view
        bookMustExist(_id)
        returns (address[] memory)
    {
        return books[_id].allBorrowers;
    }

    modifier bookMustExist(uint256 _id) {
        require(books.length > 0, "No books in the library.");
        require(_id <= books.length - 1, "Book with this ID doesn't exist.");
        _;
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