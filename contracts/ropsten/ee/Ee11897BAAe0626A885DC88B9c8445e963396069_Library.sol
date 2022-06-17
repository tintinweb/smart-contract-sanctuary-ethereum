// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Library is Ownable {
    event BooksAdded(Book[] _books);
    event BooksUpdated(UpdateBook[] _books);

    event BooksBorrowed(uint256[] _ids, address _borrower);
    event BooksReturned(uint256[] _ids, address _borrower);

    struct Book {
        string title;
        uint256 copies;
        bool isInitialized;
    }

    struct UpdateBook {
        uint256 id;
        uint256 copiesToAdd;
    }

    struct BookView {
        uint256 id;
        string title;
        uint256 copiesLeft;
    }

    struct BorrowingHistory {
        // will be used to manage duplicating borrowers list when borrowing a book multiple times
        bool isEverBorrowed;
        bool isCurrentlyBorrowed;
    }

    uint256 public constant MAX_ITEMS_PER_REQUEST = 100;

    // start from 1, 0 is reserved for non-existing
    uint256 public itemId = 1;

    mapping(string => uint256) public titleToBookId;
    mapping(uint256 => Book) public bookIdToBook;

    mapping(address => mapping(uint256 => BorrowingHistory))
        public userToBorrowedBookId;
    mapping(uint256 => address[]) public bookIdToBorrowerHistory;

    function addBooks(Book[] calldata books) external onlyOwner {
        require(books.length > 0, "Books list is empty !");
        for (uint256 i = 0; i < books.length; i++) {
            require(books[i].copies > 0, "Books copies should be > 0");
            require(
                bytes(books[i].title).length > 0,
                "Book title should not be empty !"
            );
            require(
                titleToBookId[books[i].title] == 0,
                "Book with such title already exists !"
            );

            Book memory b = Book({
                title: books[i].title,
                copies: books[i].copies,
                isInitialized: true
            });

            titleToBookId[books[i].title] = itemId;
            bookIdToBook[itemId] = b;
            itemId++;
        }

        emit BooksAdded(books);
    }

    function updateBooks(UpdateBook[] calldata books) external onlyOwner {
        require(books.length > 0, "Books list is empty !");
        for (uint256 i = 0; i < books.length; i++) {
            require(books[i].copiesToAdd > 0, "Cannot add negative quantity");

            Book storage b = bookIdToBook[books[i].id];
            require(b.isInitialized, "Book does not exist");

            b.copies += books[i].copiesToAdd;
        }

        emit BooksUpdated(books);
    }

    function borrowBooks(uint256[] calldata bookIds) external {
        require(bookIds.length > 0, "Book list is empty !");
        for (uint256 i = 0; i < bookIds.length; i++) {
            Book storage book = bookIdToBook[bookIds[i]];

            require(book.isInitialized, "Book w/ such Id does not exist !");
            require(book.copies > 0, "Requested book has no copies left !");
            require(
                !userToBorrowedBookId[msg.sender][bookIds[i]]
                    .isCurrentlyBorrowed,
                "User already borrowed that book !"
            );

            userToBorrowedBookId[msg.sender][bookIds[i]]
                .isCurrentlyBorrowed = true;
            book.copies--;

            if (!userToBorrowedBookId[msg.sender][bookIds[i]].isEverBorrowed) {
                bookIdToBorrowerHistory[bookIds[i]].push(msg.sender);
                userToBorrowedBookId[msg.sender][bookIds[i]]
                    .isEverBorrowed = true;
            }
        }

        emit BooksBorrowed(bookIds, msg.sender);
    }

    function returnBook(uint256[] calldata bookIds) external {
        require(bookIds.length > 0, "Book list is empty");
        for (uint256 i = 0; i < bookIds.length; i++) {
            require(
                bookIdToBook[bookIds[i]].isInitialized,
                "Book with such ID does not exist !"
            );
            require(
                userToBorrowedBookId[msg.sender][bookIds[i]]
                    .isCurrentlyBorrowed,
                "Book was not borrowed by this user !"
            );

            userToBorrowedBookId[msg.sender][bookIds[i]]
                .isCurrentlyBorrowed = false;
            bookIdToBook[bookIds[i]].copies++;
        }

        emit BooksReturned(bookIds, msg.sender);
    }

    // Use Pagination below
    function getAvailableBooks(uint256 startFrom, uint256 count)
        public
        view
        inQueryLimit(count)
        returns (BookView[] memory)
    {
        require(startFrom > 0, "Min start should be from ID = 1");
        uint256 length = calcPaginationLength(itemId - 1, startFrom - 1, count);
        BookView[] memory result = new BookView[](length);

        for (uint256 i = 0; i < length; i++) {
            uint256 actualIndex = startFrom + i;
            BookView memory bookView = BookView({
                id: actualIndex,
                title: bookIdToBook[actualIndex].title,
                copiesLeft: bookIdToBook[actualIndex].copies
            });
            result[i] = bookView;
        }

        return result;
    }

    function getBorrowersForBookId(
        uint256 bookId,
        uint256 startFrom,
        uint256 count
    ) public view inQueryLimit(count) returns (address[] memory) {
        require(startFrom >= 0, "Min start should be from ID = 0");
        address[] memory bookBorrowers = bookIdToBorrowerHistory[bookId];
        uint256 length = calcPaginationLength(
            bookBorrowers.length,
            startFrom,
            count
        );

        address[] memory result = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            result[i] = bookBorrowers[startFrom + i];
        }

        return result;
    }

    // arr [1,2,3,4,5]   5
    //            _ _ _  3  startFrom: 4, count: 3 => resize to max, i.e. 2
    function calcPaginationLength(
        uint256 sourceLength,
        uint256 startFrom,
        uint256 count
    ) private pure returns (uint256) {
        uint256 length = count;
        if (length > sourceLength - startFrom) {
            length = sourceLength - startFrom;
        }
        return length;
    }

    modifier inQueryLimit(uint256 count) {
        require(
            count > 0 && count <= MAX_ITEMS_PER_REQUEST,
            "Count should be bettwen 0 and Check MAX_ITEMS_PER_REQUEST"
        );
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