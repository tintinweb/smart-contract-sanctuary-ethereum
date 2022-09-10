// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {

    uint256 public favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;
    mapping(uint256 => string) public favoriteNumberToName;

    struct People {
        uint256 favoriteNumber;
        string name;
    }


    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }


    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }


    function addPerson(string memory _name, uint256 _favoriteNumber) public {

        People memory newPerson = People({
            favoriteNumber: _favoriteNumber,
            name: _name
        });
        people.push(newPerson);
        nameToFavoriteNumber[_name] = _favoriteNumber;
        favoriteNumberToName[_favoriteNumber] = _name;
    }
}