// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract SimpleStorage {
    // This gets initialized to zero!
    uint256 favouriteNumber;

    mapping(string => uint256) public nameToFavouriteNumber;

    // Instantiaing the object
    // People public person = People({favouriteNumber: 5, name: "Nischal"});

    // struct
    struct People {
        uint256 favouriteNumber;
        string name;
    }

    // Arrays
    People[] public people;

    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    // view
    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        people.push(People(_favouriteNumber, _name));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
}