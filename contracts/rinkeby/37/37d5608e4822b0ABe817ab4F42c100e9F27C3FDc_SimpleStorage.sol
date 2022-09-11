// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

contract SimpleStorage {
    uint256 favoriteNumber;

    struct People {
        uint256 number;
        string name;
    }
    People[] public persons;
    mapping(string => uint256) public nameToNumber;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _number) public {
        persons.push(People(_number, _name));
        nameToNumber[_name] = _number;
    }
}