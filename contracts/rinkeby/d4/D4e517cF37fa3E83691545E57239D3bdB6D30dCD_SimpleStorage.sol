//SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

contract SimpleStorage {
    uint256 public favoriteNumber;

    struct People {
        uint256 number;
        string peron;
    }

    People[] public people;
    mapping(string => uint256) nameToFavNumber;

    function store(uint256 _num) public {
        favoriteNumber = _num;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _num) public {
        nameToFavNumber[_name] = _num;
        people.push(People(_num, _name));
    }
}