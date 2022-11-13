// SPDX-License-Identifier: MIT

pragma solidity 0.8.8; //0.8.12 is newest as of vid

contract SimpleStorage {
    // This get initialized to zero
    uint256 favoriteNumber;

    //literally mapping the string name you type to the uint256 number
    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    //view, pure
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    /* calldata, memory, storage (can only store variables in memory for arrays, structs, and mapping types)
    calldata = temp var that cant be modified, memory = temp var that can be modified, storage = permament var that can be modified */
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}