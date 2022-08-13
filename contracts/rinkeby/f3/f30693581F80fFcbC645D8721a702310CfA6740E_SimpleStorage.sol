// SPDX-License-Identifier: MIT
pragma solidity 0.8.8; // 0.8.7 is considered one of the more stable versions

contract SimpleStorage {
    // basic types
    // boolean, uint, int, address, bytes

    // This get initalized to zero
    uint256 favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
        // retrieve();
    }

    //Free to call unless called within a contract
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string calldata _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}