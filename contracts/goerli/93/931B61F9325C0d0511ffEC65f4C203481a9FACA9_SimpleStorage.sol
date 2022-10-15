//  SPDX-License-Identifier: MIT
pragma solidity >=0.8.17; //Solidity version

// boolean, uint, int, address, bytes, string

contract SimpleStorage {
    uint256 public favoriteNumber;
    People[] public person;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function addPerson(uint256 _favoriteNumber, string memory _name) public {
        person.push(People({favoriteNumber: _favoriteNumber, name: _name}));
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }
}