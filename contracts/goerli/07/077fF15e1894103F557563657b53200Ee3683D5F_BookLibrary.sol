// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";


contract BookLibrary is Ownable {
    
    struct Book {
        string name;
        uint availableCopies;
        uint ownerCount;
        mapping(uint => address) ownersHistory;
    }

    uint public bookCount = 0;

    mapping(string => bool) private isPresent;
    mapping(address => mapping(uint => bool)) private isAlreadyIssued;
    mapping(uint => Book) public BookDatabase;

  

    function addBook(string memory _name, uint _copies)
        external
        onlyOwner 
    {
        require(!isPresent[_name]);
        isPresent[_name] = true;
        bookCount++;
        Book storage book = BookDatabase[bookCount];
        book.name = _name;
        book.availableCopies = _copies;
    }

    function addBookCopies(uint _bookId, uint _copies)
        external
        onlyOwner
    {
        require(_copies > 0);
        Book storage book = BookDatabase[_bookId];
        book.availableCopies = book.availableCopies +_copies;
    }
   
    function borrowBook(uint _id) external {
        require(!isAlreadyIssued[msg.sender][_id]);
        isAlreadyIssued[msg.sender][_id] = true;
        Book storage book = BookDatabase[_id];
        require(book.availableCopies-1 >= 0);
        book.availableCopies--;
        book.ownersHistory[book.ownerCount] = msg.sender;
        book.ownerCount++;
    }

    function returnBook(uint _id) external {
        require(isAlreadyIssued[msg.sender][_id]);
        Book storage book = BookDatabase[_id];
        book.availableCopies++;
        isAlreadyIssued[msg.sender][_id] = false;
    }

     function getAvailableBooks() external view returns (uint[] memory) {
        uint bookIndex = 0;
        for (uint index = 1; index <= bookCount; index++) {
            if (BookDatabase[index].availableCopies > 0) {
                bookIndex++;
            }
        }
        uint[] memory result = new uint[](bookIndex);
        bookIndex = 0;
        for (uint index = 1; index <= bookCount; index++) {
            if (BookDatabase[index].availableCopies > 0) {
                result[bookIndex] = index;
                bookIndex++;
            }
        }
        return result;
    }

     function getOwnerHistoryOfBook(uint _id)
        external
        view
        returns (address[] memory)
    {
        address[] memory result = new address[](BookDatabase[_id].ownerCount);
        for (uint index = 0; index < result.length; index++) {
            result[index] = BookDatabase[_id].ownersHistory[index];
        }
        return result;
    }


    function getBookDetail(uint256 _id)
        public
        view
        returns (string memory, uint256)
    {
        return (BookDatabase[_id].name, BookDatabase[_id].availableCopies);
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