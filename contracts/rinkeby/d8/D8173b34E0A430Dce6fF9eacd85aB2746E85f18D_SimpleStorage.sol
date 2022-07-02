// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleStorage {
    // a uint256 without a value will be 0
    uint256 public favoriteNumber;
    //mappings
    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view , pure
    // view is another getter function
    // pure is if your changing state in the block
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // here we add our person to our people array using our People struct
    function addPerson(uint256 _favoriteNumber, string memory _name) public {
        // People thats capitlalized is from our People struct
        people.push(People(_favoriteNumber, _name));
        // adding a person to our map
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}