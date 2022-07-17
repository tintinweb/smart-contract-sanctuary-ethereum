// SPDX-License-Identifier: MIT
pragma solidity 0.8.7; // ^ any versino above is ok. can use operators for range.

contract SimpleStorage {
    uint256 favoriteNumber;

    mapping(string => uint256) public nameToFavorite;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view, pure
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));

        nameToFavorite[_name] = _favoriteNumber;
    }
}