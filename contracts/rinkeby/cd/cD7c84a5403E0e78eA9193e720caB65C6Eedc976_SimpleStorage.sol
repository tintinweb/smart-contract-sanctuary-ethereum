// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; //solidity version

contract SimpleStorage {
    //boolean, uint, int address, bytes

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    mapping(string => uint256) public peopleMapping;

    People[] public people;

    function addPerson(string calldata _name, uint256 _favoriteNumber) public {
        people.push(People({favoriteNumber: _favoriteNumber, name: _name}));
        peopleMapping[_name] = _favoriteNumber;
    }

    function retreiveNumber(string calldata _name)
        public
        view
        returns (uint256)
    {
        return peopleMapping[_name];
    }
}