// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    uint256 public number; // By default it is internal
    People[] public people;

    mapping(string => uint256) public nameToFavouriteNumber;

    struct People {
        uint256 favouriteNumber;
        string name;
    }

    function store(uint _number) public virtual {
        number = _number;
    }

    function addPeople(string memory _name, uint256 _favouriteNumber) public {
        People memory newPeople = People({
            name: _name,
            favouriteNumber: _favouriteNumber
        });
        people.push(newPeople);
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }

    function getStore() public view returns (uint256) {
        return number;
    }
}