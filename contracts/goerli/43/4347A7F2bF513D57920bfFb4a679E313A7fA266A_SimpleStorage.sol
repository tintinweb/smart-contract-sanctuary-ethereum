// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

struct People {
    uint256 favoriteNumber;
    string name;
}

contract SimpleStorage {
    uint256 public favoriteNumber;
    People[] public people;

    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function storeAndRetrieve(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
        retrieve();
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string calldata _name, uint256 _favoriteNumber) public {
        people.push(People({name: _name, favoriteNumber: _favoriteNumber}));

        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}