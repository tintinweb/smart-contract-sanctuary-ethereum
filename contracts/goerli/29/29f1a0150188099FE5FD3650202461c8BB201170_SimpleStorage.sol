// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 public favoriteNumber;

    People public person = People({favoriteNumber: 2, name: "menge"});

    mapping(string => uint256) public nameToFavoriteNumber;
    // new type of People created
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // uint256[] public favoriteNumberList;
    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view, pure
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // calldata, memory, storage
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // People memory newPerson = People(
        //     favoriteNumber: _favoriteNumber,
        //     _name
        // });
        // People memory newPerson = People(_favoriteNumber, name: _name); // This is also possible
        people.push(People(_favoriteNumber, _name));

        nameToFavoriteNumber[_name] = _favoriteNumber; // lookup table dictionary
    }
}