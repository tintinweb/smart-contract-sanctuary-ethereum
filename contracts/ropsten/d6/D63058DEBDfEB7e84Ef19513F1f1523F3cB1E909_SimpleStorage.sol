// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

contract SimpleStorage{
    uint256 public favoriteNumber;

    struct People{
        uint256 favoriteNumber;
        string name;
    }
    People[] public people;
    mapping(string => uint256) public nameToFavoriteNumber;

    function addPerson(string memory _name, uint256 _favoriteNumber ) public {
        people.push(People({ favoriteNumber: _favoriteNumber, name: _name }));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns(uint256) {
        return favoriteNumber;
    }
}