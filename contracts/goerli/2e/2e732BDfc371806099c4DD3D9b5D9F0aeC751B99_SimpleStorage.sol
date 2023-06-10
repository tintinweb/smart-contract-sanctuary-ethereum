// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 favoriteNumber;

    struct person {
        string name;
        uint256 favoriteNumber;
    }

    person[] people;

    mapping(string => uint256) nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(person(_name, _favoriteNumber));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    function getPersonDetailFromArray(
        uint256 _personIndex
    ) public view returns (person memory) {
        return people[_personIndex];
    }

    function getPersonFavoriteNumber(
        string memory _name
    ) public view returns (uint256) {
        return nameToFavoriteNumber[_name];
    }
}