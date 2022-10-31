// SPDX-License-Identifier: ISC
pragma solidity ^0.8.0;
pragma abicoder v2;
import "@openzeppelin/contracts/access/Ownable.sol";

contract Library is Ownable {

    struct BookRecord {
        string name;
        uint8 copies;
        address[] rentalHistory;
    }

    mapping( address => bytes32[] ) currentRentals;
    mapping( bytes32 => bool ) public enteredBooks;
    mapping( bytes32 => BookRecord) public bookLedger;
    bytes32[] public availableBooks;
    
    event LogBookAdded( bytes32 id, string bookName, uint8 copies );
    event LogBookRented( bytes32 id, address user );
    event LogBookReturned( bytes32 id, address user );

 
    modifier bookExists( bytes32 bookId) {
        require( enteredBooks[ bookId ], "There's no such book in the library.");
        _;
    }
    
    function addBook( string memory name, uint8 copies ) external onlyOwner {
        require( copies != 0, "You can't add 0 books." );

        bytes32 bookId = keccak256( abi.encodePacked( name ) );

        if( enteredBooks[ bookId ] ) {
            bookLedger[ bookId ].copies += copies;
        }
        else {
            bookLedger[ bookId ] = BookRecord( name , copies, new address[](0));
            availableBooks.push( bookId );
            enteredBooks[ bookId ] = true;
        }
        
        emit LogBookAdded( bookId, name, copies );
    }

    function rentBook( bytes32 bookId ) external bookExists( bookId ) {
        require( bookLedger[ bookId ].copies > 0, "Book isn't currently available." );
        require( !_checkIfRentedAlready( msg.sender, bookId ), "User rented that book already." );

        if( bookLedger[ bookId ].copies == 1 ) {
            _removeFromAvailableBooks( bookId );
        }
        bookLedger[ bookId ].copies -= 1;
        currentRentals[ msg.sender ].push( bookId );
        bookLedger[ bookId ].rentalHistory.push( msg.sender );

        emit LogBookRented( bookId, msg.sender );
    }
    
    function returnBook( bytes32 bookId ) external bookExists( bookId ) {
        require( _checkIfRentedAlready( msg.sender, bookId ), "You can't return a book you didn't rent." );

        if( bookLedger[ bookId ].copies == 0 ) {
            availableBooks.push( bookId );
        }
        bookLedger[ bookId ].copies += 1;
        _removeFromCurrentRetals( msg.sender, bookId );
        
        emit LogBookReturned( bookId, msg.sender );
    }

    function showBookHistory( bytes32 bookId ) external view returns( address[] memory ) {
        return bookLedger[ bookId ].rentalHistory;
    }

    function showAllAvailableBooks() external view returns( bytes32[] memory ) {
        return availableBooks;
    }

    //--- PRIVATE HELPER METHODS

    function _checkIfRentedAlready( address userAddress, bytes32 bookId ) private view returns ( bool ) {
        bool rented = false;
        for( uint i=0; i < currentRentals[ userAddress ].length; i++ ) {
            if( currentRentals[ userAddress ][ i ] == bookId ) {
                rented = true;
                break;
            }
        }
        return rented;
    }

    function _removeFromCurrentRetals( address userAddress, bytes32 bookId ) private {
        for( uint i=0; i < currentRentals[ userAddress ].length; i++ ) {
            if( currentRentals[ userAddress ][ i ] == bookId ) {
                currentRentals[ userAddress ][ i ] = 
                currentRentals[ userAddress ][currentRentals[ userAddress ].length - 1];
                currentRentals[ userAddress ].pop();
                break;
            }
        }
    }
    
    function _removeFromAvailableBooks( bytes32 bookId ) private {
        for( uint i=0; i < availableBooks.length; i++ ) {
            if( availableBooks[ i ] == bookId ) {
                availableBooks[ i ] = availableBooks[ availableBooks.length -1 ];
                availableBooks.pop();
            }
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