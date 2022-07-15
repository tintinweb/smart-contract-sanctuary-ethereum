// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract SimpleStorage {
    // this gets initialized to zero if no  = <your#>;
    uint256 favoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }
    // uint256[] public anArray;
    People[] public people;

    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // types of data(6) : stack, code, logs
    // other types of data: calldata- temp can't be mod, memory - temp can be mod, storage - perm can be mod
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}