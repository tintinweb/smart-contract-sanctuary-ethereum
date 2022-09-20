// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

contract SimpleStorage {
    struct People {
        int256 favoiteNumber;
        string name;
    }

    People[] peoples;

    mapping(string => int256) public nameToFavoriteNumber;

    function store(string calldata _name, int256 _favoriteNumber) public {
        peoples.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    function retrieve() public view returns (People[] memory) {
        return peoples;
    }
}