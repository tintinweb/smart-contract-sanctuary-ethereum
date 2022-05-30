// SPDX-License-Identifier:MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    uint256 public favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    function store(uint256 _favNumber) public virtual {
        favoriteNumber = _favNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNum) public {
        people.push(People(_favoriteNum, _name));
        nameToFavoriteNumber[_name] = _favoriteNum;
    }
}