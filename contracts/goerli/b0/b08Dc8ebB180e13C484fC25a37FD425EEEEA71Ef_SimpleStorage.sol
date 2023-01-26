// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract SimpleStorage {
    uint256 public favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    People[] public people;

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // since we don't need _name after this function runs, we store it as memory or calldata
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    struct People {
        uint256 favoriteNumber;
        string name;
    }
}