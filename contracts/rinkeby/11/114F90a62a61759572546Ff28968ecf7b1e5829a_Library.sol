// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";


contract Library is Ownable{

    event AddedBook(uint bookId, string name, uint8 numOfCopies);
    event NewBorrowing(uint bookId, address borrower);
    event NewReturn(uint bookId, address borrower);

    uint8 private constant UNBORROWED = 0;
    uint8 private constant PAST_BORROWED = 1;
    uint8 private constant BORROWED = 2;

    struct LibraryBookRecord {
        string name;
        uint8 numOfCopies;
        uint8 numOfBorrowedCopies;
    }

    uint[] private booksIndexList;

	mapping(uint => LibraryBookRecord) private books;
    mapping(uint => mapping(address => uint8)) private borrowers;
    mapping(uint => address[]) private anytimeBorrowers;

    //List all books. We create an array of actual book info records for each index.
    //This way there's a 1-to-1 link between id and book on the frontend
    function listBooks() view public returns(LibraryBookRecord[] memory, uint[] memory){

        uint lengthOfbooksIndexList = booksIndexList.length;
        LibraryBookRecord[] memory booksArray = new LibraryBookRecord[](booksIndexList.length);

        for(uint i=0; i < lengthOfbooksIndexList ; i++){
            uint bookId = booksIndexList[i];
            LibraryBookRecord memory book = books[bookId];
            booksArray[i] = book;
        }
        return (booksArray, booksIndexList);
    }

    function addBook(string memory _name, uint8 _numOfCopies) public onlyOwner{
        require(_numOfCopies > 0, "Number of copies should be more than 0");

        uint bookId = uint(keccak256(abi.encodePacked(_name)));

        if(bookExistsHelper(bookId)){
            books[bookId].numOfCopies = books[bookId].numOfCopies + _numOfCopies;
        }
        else{
            books[bookId] = LibraryBookRecord(_name, _numOfCopies, 0);
            booksIndexList.push(bookId);
        }
        
        emit AddedBook(bookId, _name, _numOfCopies);

    }

    //Borrowing book only if the book has enough remaining copies unborrowed and the requester isn't borrowing renting the book
    function borrowBook(uint _bookId) public bookAvailable(_bookId) isNotCurrentBorrower(_bookId, msg.sender) {

        if(!hasBeenBorrowerHelper(_bookId, msg.sender)){
            anytimeBorrowers[_bookId].push(msg.sender);
        }
            

        borrowers[_bookId][msg.sender] = BORROWED;
        books[_bookId].numOfBorrowedCopies++;

        emit NewBorrowing(_bookId, msg.sender);
    }

    //Return the book by removing the borrower from the list of current borrowers (only if the requester is currently borrowing it)
    function returnBook(uint _bookId) public bookExists(_bookId) isCurrentBorrower(_bookId, msg.sender){
       borrowers[_bookId][msg.sender] = PAST_BORROWED;
       books[_bookId].numOfBorrowedCopies--;
 
        emit NewReturn(_bookId, msg.sender);
   }

    function listAllPastBorrowersOfBook(uint _bookId) public view bookExists(_bookId) returns(address[] memory){
        return(anytimeBorrowers[_bookId]);   
    }

    modifier bookExists(uint _bookId){
        require(bookExistsHelper(_bookId), "Book ID doesn't exist");
        _;
    }

    modifier bookAvailable(uint _bookId){
        require(bookAvailableHelper(_bookId), "No available copies of the book");
         _;
   }

    modifier isCurrentBorrower(uint _bookId, address _person) {
        require(isCurrentBorrowerHelper(_bookId, _person), "User has not currently borrowed this book");
        _;
    }

    modifier isNotCurrentBorrower(uint _bookId, address _person) {
        require(!isCurrentBorrowerHelper(_bookId, _person), "User has already currently borrowed this book");
        _;
    }

    // Helper function to check if a book exists
    function bookExistsHelper(uint _bookId) private view returns(bool){
        return (books[_bookId].numOfCopies != 0);
    }

    // Helper function to check if a book is available
    function bookAvailableHelper(uint _bookId) private view bookExists(_bookId) returns(bool){
        return (books[_bookId].numOfCopies > books[_bookId].numOfBorrowedCopies);
    }

    //Helper function making sure a book exists and checking if a specific person is currently borrowing it
    function isCurrentBorrowerHelper(uint _bookId, address _person) private view bookExists(_bookId) returns(bool) {
        uint borrowingStatus = borrowers[_bookId][_person];
        return (borrowingStatus == BORROWED? true: false);
    }

    //Helper function making sure a book exists and checking if a specific person has ever borrowed. Used to add people in the list of borrowers
    function hasBeenBorrowerHelper(uint _bookId, address _person) private view bookExists(_bookId) returns(bool) {
        uint borrowingStatus = borrowers[_bookId][_person];
        return ((borrowingStatus == BORROWED || borrowingStatus == PAST_BORROWED)? true: false);
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