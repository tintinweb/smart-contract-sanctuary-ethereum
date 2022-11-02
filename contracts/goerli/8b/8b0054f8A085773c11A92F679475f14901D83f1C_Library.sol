// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.12 <0.9.0;

// import "./2_Owner.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Library is Ownable {

    struct Book {
        uint id;
        uint copies;
    }

    Book[] public books;

    mapping (address =>  mapping(uint => Book)) userToBooks;
    // mapping (address => uint) userToBorrowedBooksCount;
    mapping(uint => Book) idToBook;
    mapping(uint => address[]) bookIdToAllBorrowers;

    // string[] public allBookTitles;
    mapping(uint => uint) idToRowInAllBooksInfo;
    uint[][] public allBooksInfo;

    event ShowBook(uint[][] allBooksInfo);
    event ShowAddress(address addr);

    string public message = "sussy";

    //admin
    function addNewBook(uint _id, uint _copies) public onlyOwner() {
        Book memory book = Book(_id, _copies);
        books.push(book);
        idToBook[_id] = book;
        // idToRowInAllBooksInfo[_id] = allBooksInfo.length;
        allBooksInfo.push([_id, _copies]);
    }

    //user
    function showAvailableBooks() public {
        emit ShowBook(allBooksInfo);
    }

    function findBookById(uint _id) public view returns(Book memory) {
        return idToBook[_id];
    }

    function checkIfIHaveBook(uint _id) public view returns(bool) {
        if(userToBooks[msg.sender][_id].id != 0){
            return true;
        }
        return false;
    }

    function _checkIfUserHasBook(address _user, uint _id) private view returns(bool) {
        if(userToBooks[_user][_id].id != 0){
            return true;
        }
        return false;
    }

    // function removeBook(Book[] storage _books, uint _id) private {
    //     Book storage book;
    //     for(uint i = 0; i < _books.length; i++){
    //         if(_books[i].id == _id){
    //             book = _books[i];
    //         }
    //     }
        
    //     for(uint i = 0; i < _books.length; i++){
    //         if(_books[i].id == _id){
    //             _books[i] = _books[_books.length - 1];
    //             _books.pop();
    //         }
    //     }
    // }

    function borrowBook(uint _id) public {
        address user = msg.sender;
        Book memory book = idToBook[_id];

        // require(!_checkIfUserHasBook(user, _id));
        // require(book.copies > 0);

        userToBooks[user][_id] = book;

        bookIdToAllBorrowers[book.id].push(user);

        allBooksInfo[idToRowInAllBooksInfo[_id]][1]--;
        // book.copies--;
    }

    function returnBook(uint _id) public {
        address user = msg.sender;

        require(_checkIfUserHasBook(user, _id));

        delete userToBooks[user][_id];

        allBooksInfo[idToRowInAllBooksInfo[_id]][1]++;
    }

    function seeAllAddressesBorrowed(uint _id) public {
        for(uint i = 0; i < bookIdToAllBorrowers[_id].length; i++){
            emit ShowAddress(bookIdToAllBorrowers[_id][i]); 
        }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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