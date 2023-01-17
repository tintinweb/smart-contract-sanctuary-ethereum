// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract SimpleStorage {
    uint256 favoriteNumber;
    string favoriteName;

    struct People {
        uint256 favoriteNumber;
        string name;
    }
    // uint256[] public anArray;
    People[] public people;

    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    function storeName(string memory _favoriteName) public {
        favoriteName = _favoriteName;
    }

    function retrieveName() public view returns (string memory) {
        return favoriteName;
    }
}