// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;
import "@openzeppelin/contracts/access/Ownable.sol";

contract Library is Ownable {

  event LogAddedNewBook(uint bookId);
	event LogBorrowedBook(uint bookId);
	event LogReturnedBook(uint bookId);

    struct Book {
	      uint bookId;
        string title;
        string author;
        uint availableCopies;
    }
	
    Book[] public books ;

    mapping (uint => address[]) public historicalBorrowersByBook;
    mapping (uint => address[]) public currentBorrowersByBook;

    function addBook(string calldata title,string calldata author,uint availableCopies) public onlyOwner{
        uint id = books.length;
        books.push(Book(id,title,author,availableCopies));
        emit LogAddedNewBook(id);   
    }
	   
    function listAvailableBooks() public view returns (Book[] memory){
	    Book[] memory result  = new Book[](books.length);
		uint counter = 0;
        for (uint i = 0; i < books.length; i++) {
            if (books[i].availableCopies > 0) {
                result[counter] = books[i];
				counter++;
			}
		}
		return result;
	}

    function checkBookBorrowabilityByAddress(uint bookId,address borrower) public view returns (bool){
    
	    for(uint i=0;i<currentBorrowersByBook[bookId].length;i++){
            if(currentBorrowersByBook[bookId][i] == borrower){
			    return false;
			}
        }
    return true;		
		
    }	
	
	function dropCurrentBorrower(uint bookId,address returner) public {
	
	    for(uint i=0;i<currentBorrowersByBook[bookId].length;i++){
            if(currentBorrowersByBook[bookId][i] == returner){
			    currentBorrowersByBook[bookId][i] = currentBorrowersByBook[bookId][currentBorrowersByBook[bookId].length-1];
				currentBorrowersByBook[bookId].pop;
			}
        }
	}
    

    function borrowBook(uint _bookId) public{
        // book available copies must be > 0
		require(books[_bookId].availableCopies > 0);
		
		// borrower address must not be in the current borrowers by book mapping
		require(checkBookBorrowabilityByAddress(_bookId,msg.sender));
        
		// add the borrower address to history of borrowers of that book
		historicalBorrowersByBook[_bookId].push(msg.sender);
        
		// add the borrower address to current borrowers of that book
		currentBorrowersByBook[_bookId].push(msg.sender);		
		
		// decrement available copies of this book
		books[_bookId].availableCopies--;
        
		// emit borrowed book
		emit LogBorrowedBook(_bookId);
    }
	
	function returnBook(uint bookId) public{
	    // book returner must be among the current borrowers of that book
		require(!checkBookBorrowabilityByAddress(bookId, msg.sender));
        
		// drop the address of the returner from the current borrowers mapping
		dropCurrentBorrower(bookId, msg.sender);
        
		// increment available copies of that book by one		 
		books[bookId].availableCopies++;
	}
	
	function listHistoricalBorrowers(uint bookId) public view returns (address[] memory){
	    address[] memory result  = new address[](currentBorrowersByBook[bookId].length);
	    uint counter = 0;
	    for (uint i = 0; i < currentBorrowersByBook[bookId].length; i++) {
		    result[counter] = currentBorrowersByBook[bookId][i];
		    counter++;
		}
		return result;
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