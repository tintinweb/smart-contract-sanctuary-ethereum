// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Library is Ownable {
    event addedBook(string name, uint256 copies);
    event addedCopies(string name, uint256 copies);
    error notPaying();
    error alredyBorrwing(address user);

    uint256 public count;
    uint256 public immutable PRICE = 10000;
    struct Book {
        string name;
        uint256 copies;
    }

    constructor() Ownable() {}

    //user => current borrowing book index
    mapping(address => uint256) public currentlyBorrowing;
    //book name => index
    mapping(string => uint256) public indexes;
    //index => book
    mapping(uint256 => Book) public books;
    //bookIndex => previous borrowers
    mapping(uint256 => mapping(address => bool)) borrowedBooks;

    function withdraw() external payable onlyOwner {
        require(address(this).balance > 0, "No eth to withdraw");
        payable(msg.sender).transfer(address(this).balance);
    }

    function addBook(string calldata _name, uint256 _copies)
        external
        onlyOwner
    {
        if (indexes[_name] != 0) {
            books[indexes[_name]].copies += _copies;
            emit addedCopies(_name, _copies);
            return;
        } else {
            ++count;
            books[count] = Book({name: _name, copies: _copies});
            indexes[_name] = count;
            emit addedBook(_name, _copies);
        }
    }

    function borrowBook(uint256 _index) external payable {
        //msg.sender    49436
        //sender        49450
        //address sender = msg.sender;

        if (msg.value < PRICE) {
            revert notPaying();
        }

        if (currentlyBorrowing[msg.sender] > 0) {
            revert alredyBorrwing(msg.sender);
        }
        //storage b 49371   56777
        //books[]   49436   56852
        Book storage b = books[_index];
        //check if enough books
        require(b.copies > 0, "zero books left");
        --b.copies;
        //note book to borrower
        currentlyBorrowing[msg.sender] = _index;
        //note borrower to book
        borrowedBooks[_index][msg.sender] = true;
    }

    function returnCurrentBook() external {
        uint256 _index = currentlyBorrowing[msg.sender];
        require(_index > 0, "not borrowng");
        currentlyBorrowing[msg.sender] = 0;
        ++books[_index].copies;
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