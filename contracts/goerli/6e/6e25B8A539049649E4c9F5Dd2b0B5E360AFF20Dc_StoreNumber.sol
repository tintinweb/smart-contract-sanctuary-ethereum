// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract StoreNumber {
    mapping(string => uint256) nameToNumber;

    uint256 favoriteNumber;

    struct People {
        string _name;
        uint256 favoriteNumber;
    }

    function retrieve() external view returns (uint256) {
        return (favoriteNumber);
    }

    function store(uint256 _favoriteNumber) external {
        favoriteNumber = _favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) external {
        nameToNumber[_name] = _favoriteNumber;
    }
}