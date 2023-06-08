// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract SimpleStorage {
    uint256 favoriteNumber;

    mapping(string => uint256) public nameTofavoriteNumber;

    struct People {
        string name;
        uint256 favoriteNumber;
    }

    uint256[] public favoriteNumberList;
    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // calldata, memory, storage

    // calldata - temporary variable that can't be modified
    // memory - temporary variable that can be modified
    // storage - permanent variable that can be modified

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_name, _favoriteNumber));
        nameTofavoriteNumber[_name] = _favoriteNumber;
    }
}

// 0xF4Ab7840b1AEA3994E1805Be0E713b108908415550