/**
 *Submitted for verification at Etherscan.io on 2022-03-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;



// File: basic_storage.sol

//Defining a contact Storage
contract Storage {
    uint256 bookshelf_id;

    struct book {
        string book_name;
        string author_name;
        uint256 book_id;
    }
    book book_struct;
    book[] public book_array;

    function book_storage(
        string memory b_n,
        string memory a_name,
        uint256 b_id
    ) public {
        book_struct = book(b_n, a_name, b_id);
        book_array.push(book_struct);
    }

    //This is a simple storage contract that involves users storing a simple number and retrieving it

    //when not specified the default specifier keyword is Internal
    uint256 number;

    //Defining a store function:
    function store(uint256 num) public {
        number = num;
    }

    //Define a function that retrieves the number stored by the user
    function retrieve() public view returns (uint256) {
        return number;
    }
}