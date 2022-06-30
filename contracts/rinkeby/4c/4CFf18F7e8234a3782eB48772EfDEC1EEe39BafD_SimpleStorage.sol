// SPDX-License-Identifier: MIT
// to compile : yarn hardhat compile
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 public favoriteNumber;

    //setting it to virtual so we can override it
    function store(uint256 _favNum) public virtual {
        favoriteNumber = _favNum;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    struct People {
        uint256 favoriteNumber;
        string name;
    }
    People public person = People({favoriteNumber: 23, name: "Wahaj"});
    People[] public people;
    mapping(string => uint256) public nameToNumber;

    function addPerson(string memory name, uint256 _favoriteNumber) public {
        People memory newPerson = People({
            favoriteNumber: _favoriteNumber,
            name: name
        });
        people.push(newPerson);
        nameToNumber[name] = _favoriteNumber;
    }
}