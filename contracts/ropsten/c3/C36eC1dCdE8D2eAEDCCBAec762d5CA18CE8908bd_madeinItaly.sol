/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/*
https://www.youtube.com/watch?v=NDK4IuEirB0
*/

/*
It keeps an array of objects, where an object is a struct representing
a product with 3 attributes: city, year, and owner
*/

contract madeinItaly {

    //state variable
    struct Product {
        string city;
        uint year;
        address owner;
    }

    Product[] public ProductList; // array of objects
    uint public n_prods = ProductList.length;

    error yearOverflow(uint year);

    function productInsert( string memory city, uint year) external {
        require(year < 2023, "year > 2022");
        /*
        if (year > 2022) {
            revert yearOverflow(year);
        }
        */
        n_prods += 1;
        ProductList.push(Product(city, year, msg.sender));
    }

}