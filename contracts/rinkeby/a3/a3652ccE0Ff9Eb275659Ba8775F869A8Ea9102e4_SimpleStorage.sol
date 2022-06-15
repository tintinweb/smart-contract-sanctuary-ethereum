// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

contract SimpleStorage {
    uint256 favorateNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public {
        favorateNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favorateNumber;
    }

    function addPersion(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}