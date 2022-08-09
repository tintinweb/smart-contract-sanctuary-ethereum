// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

contract SimpleStorage {
    //vars aoutomatically initialized to 0
    uint256 public favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    // struct effectively creates a new type "People" that consists of both uint and string
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // The people array is now an array of type People[]
    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view only allows you to read what is already there (no modification)
    //returns specifies the type of the var
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        People memory newPerson = People({
            favoriteNumber: _favoriteNumber,
            name: _name
        });
        people.push(newPerson);
        //name is the key to the value of the favoritenumber
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}