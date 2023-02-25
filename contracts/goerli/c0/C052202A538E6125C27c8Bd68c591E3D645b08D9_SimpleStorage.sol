//SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract SimpleStorage {
    uint256 testFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _fav) public {
        testFavoriteNumber = _fav;
    }

    function retrieve() public view returns (uint256) {
        return testFavoriteNumber;
    }

    function addPeople(uint256 _favoriteNumber, string memory _name) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}