// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint favoriteNumber;

    //Struct People
    struct People {
        string name;
        uint favnumber;
    }

    //a mapping of name to favorite number
    mapping(string => uint256) public nameToFavoriteNumber;
    //An array of structs
    People[] public people;

    //function to set favorite number
    function store(uint _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    //function to retrieve the value of favorite number
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    //function to push into the people array
    function setPeople(string memory _name, uint _favnumber) public {
        people.push(People(_name, _favnumber));
        nameToFavoriteNumber[_name] = _favnumber;
    }
}