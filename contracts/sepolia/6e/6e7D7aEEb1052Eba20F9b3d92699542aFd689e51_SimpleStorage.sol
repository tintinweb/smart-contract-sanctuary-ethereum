// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    //uint256[] public favoriteNumbersList;
    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}

// 0x0be557c154f8f80A3c5Ace6Be60a168f501a8a2C