//SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract SimpleStorage {
    uint256 public favoriteNumber;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    mapping(string => uint256) public nameToFavoriteNumber;

    People[] public person;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    function create(uint256 _favoriteNumber, string memory _name) public {
        person.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    function getPeople() public view returns (People[] memory) {
        return person;
    }
}