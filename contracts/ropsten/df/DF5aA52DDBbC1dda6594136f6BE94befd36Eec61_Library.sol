// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./Helpers.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Library is Ownable{

    Helpers helpersContract = new Helpers();

    struct Book {
        uint id;
        string name;
        uint quantity;
        bool exists;
    }

    uint counter;

    Book[] public LibraryArchive;

    mapping(uint => Book) BookIndex;

    mapping(uint => address[]) BookBorrowHistory;

    mapping(address => uint[]) ClientBorrowList;

    modifier shouldExist(uint bookId){
        require(BookIndex[bookId].exists,"Book does not exist in library!");
        _;
    }

    function AddBook(string calldata bookName, uint quantity) public onlyOwner{
        if(LibraryContainsBook(bookName) || BookIndex[counter].exists){
            revert("This book exists in the library!");
        }
        if(quantity < 1){
            revert("Quantity cannot be less than 1!");
        }

        Book memory newBook;
        newBook.id = counter;
        newBook.name = bookName;
        newBook.quantity = quantity;
        newBook.exists = true;

        BookIndex[counter] = newBook;
        LibraryArchive.push(newBook);

        counter++;
    }

    function BorrowBook(uint bookId) public shouldExist(bookId){    
        if(BookIndex[bookId].quantity==0){
            revert("This book is out of stock currently!");
        }    
        if(helpersContract.intArrContainsValue(bookId, ClientBorrowList[msg.sender])){
            revert("You've already borrowed that book!");
        }

        ClientBorrowList[msg.sender].push(bookId);


        if(!helpersContract.addressArrContainsValue(msg.sender, BookBorrowHistory[bookId])){
            BookBorrowHistory[bookId].push(msg.sender);        
        }

        BookIndex[bookId].quantity --;
        LibraryArchive[bookId].quantity --;
    }

    function ReturnBook(uint bookId) public shouldExist(bookId){
        if(!helpersContract.intArrContainsValue(bookId, ClientBorrowList[msg.sender])){
            revert("You havent borrowed that book!");
        }
  
        //remove book from list of borrowed books for the specific client
        removeIntArrElement(ClientBorrowList[msg.sender], bookId);
        BookIndex[bookId].quantity ++;
        LibraryArchive[bookId].quantity ++;
    }

    function BorrowHistory(uint bookId) public view shouldExist(bookId) returns (address[] memory){
        return BookBorrowHistory[bookId];
    }

    function LibraryContainsBook(string calldata bookName) private view returns (bool){
        for(uint i=0;i<LibraryArchive.length;i++){
            if(helpersContract.compareStrings(LibraryArchive[i].name, bookName)){
                return true;
            }
        }
        return false;
    }

    function removeIntArrElement(uint[] storage array, uint id) internal{
         for (uint i=0; i < array.length; i++) {
            if (id == array[i]) {
                array[i] = array[array.length - 1];
                array.pop();
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Helpers{
    function intArrContainsValue(uint value, uint[] memory array) public pure returns(bool){   
        for (uint i=0; i < array.length; i++) {
            if (value == array[i]) {     
                return true;
            }
        }
        return false;
    }

    function addressArrContainsValue(address value, address[] memory array) public pure returns(bool){   
        for (uint i=0; i < array.length; i++) {
            if (value == array[i]) {     
                return true;
            }
        }
        return false;
    }

    function compareStrings(string memory a, string memory b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
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