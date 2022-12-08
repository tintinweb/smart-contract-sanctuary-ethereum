// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

contract SimpleStorage {
    uint256 private s_favoriteNumber;

    struct People {
        uint256 st_favoriteNumber;
        string st_name;
    }

    People[] private person;
    mapping(string => uint256) private nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public {
        s_favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return s_favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        person.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    function getPersonDetails(uint256 _personIdx) public view returns (People memory) {
        return person[_personIdx];
    }

    function getFavoriteNumberOfPerson(string memory _name) public view returns (uint256) {
        return nameToFavoriteNumber[_name];
    }
}