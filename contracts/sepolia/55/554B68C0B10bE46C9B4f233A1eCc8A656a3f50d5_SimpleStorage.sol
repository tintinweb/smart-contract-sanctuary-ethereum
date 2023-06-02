// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

contract SimpleStorage {
    // i create a string storage :)

    string myFavouritegirlName;

    struct People {
        string myFavouritegirlName;
    }
    People[] public MyGirls;

    function store(string memory _name) public {
        //i store a name an i canr set it for two places
        //in a function
        //it's so awesome "give me" five
        myFavouritegirlName = _name;
        MyGirls.push(People(_name));
    }

    //in this function i try to do something new
    function get() public view returns (string memory) {
        return myFavouritegirlName;
    }
}