/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * @title Storage with CRUD operations
 * @author Siarhei ([email protected])
 * @notice You can use this contract only for dev purpose
 * @dev All function calls are currently implemented without side effects
 */
contract StorageCRUD {
    struct Book {
        uint256 id; // Book id
        string name; // Book name
        string author; // Who is the author
        uint256 rating; // Rating of this book
        uint256 createdAt; // Date of book creation
        uint256 modifiedAt; // Date of last modification
    }

    Book[] private books;
    uint256 private nextID;

    error NotFound();

    event CreateBook(uint256 indexed id, string indexed name);
    event UpdateBook(
        uint256 indexed id,
        string indexed name,
        string author,
        uint256 rating
    );
    event DeleteBook(uint256 indexed id);

    /**
     * @dev Register new book and save into Storage (C in CRUD)
     * @param name of new book
     * @param author of new book
     * @param rating of new book
     */
    function create(
        string memory name,
        string memory author,
        uint256 rating
    ) external {
        books.push(
            Book({
                id: nextID,
                name: name,
                author: author,
                rating: rating,
                createdAt: block.timestamp,
                modifiedAt: block.timestamp
            })
        );

        emit CreateBook(nextID, name);
        nextID++;
    }

    /**
     * @dev Get the book from Storage (R in CRUD)
     * @param id The id number of the book in Storage
     */
    function read(uint256 id)
        external
        view
        returns (
            Book memory
        )
    {
        uint256 index = findIndex(id);
        return books[index];
    }

    /**
     * @dev Modify the book in Storage (U in CRUD)
     * @param id of the book
     * @param name of new book
     * @param author of new book
     * @param rating of new book
     */
    function update(
        uint256 id,
        string memory name,
        string memory author,
        uint256 rating
    ) external {
        uint256 i = findIndex(id);
        books[i].name = name;
        books[i].author = author;
        books[i].rating = rating;
        books[i].modifiedAt = block.timestamp;

        emit UpdateBook(id, name, author, rating);
    }

    /**
     * @dev Remove the book from Storage (D in CRUD)
     * @param id of the book
     */
    function destroy(uint256 id) external {
        delete books[findIndex(id)];
        emit DeleteBook(id);
    }

    /**
     * @dev Get all books from Storage
     * @return Book as struct data
     */
    function getAll() external view returns (Book[] memory) {
        return books;
    }

    /**
     * @dev Internal util function to find index of the book
     * @param id of the book
     * @return position number in books array, otherwise revert with error NotFound
     */
    function findIndex(uint256 id) internal view returns (uint256) {
        for (uint256 i; i < books.length; i++) {
            if (books[i].id == id) return i;
        }

        revert NotFound();
    }
}