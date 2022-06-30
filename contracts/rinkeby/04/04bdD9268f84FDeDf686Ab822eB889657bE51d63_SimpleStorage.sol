//SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract SimpleStorage {
    uint256 favoriteNumber;

    struct People {
        uint favoriteNumber;
        string name;
    }

    People[] public people;

    mapping(string => uint) public nameToNumber;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function get() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(uint _favoriteNumber, string memory _name) public {
        people.push(People(_favoriteNumber, _name));
        nameToNumber[_name] = favoriteNumber;
    }
}