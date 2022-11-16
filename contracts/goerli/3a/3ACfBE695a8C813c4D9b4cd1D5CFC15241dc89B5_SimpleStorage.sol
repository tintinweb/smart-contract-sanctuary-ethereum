// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

contract SimpleStorage {

    //this gets initialized to 0
    uint256 public favoriteNumber;
    // People public person = People({ favoriteNumber: 2, name: "Rob"});  <-- tak mozna wprowadzić manualnie

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // uint256[] public favoriteNumberList;
    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    } 

    function retrieve() view public returns(uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}