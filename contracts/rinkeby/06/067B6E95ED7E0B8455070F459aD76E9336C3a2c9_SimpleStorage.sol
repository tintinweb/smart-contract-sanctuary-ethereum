//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; //solidity version

//contract is a class
contract SimpleStorage {
    uint256 public favoriteNumber; //default value is 0

    //struct
    struct People {
        uint256 favoriteNumber;
        string name;
    }
    People[] public people;

    //mapping initialises all keys with 0
    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    //view, pure functions do not require gas to run
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        People memory newPerson = People(_favoriteNumber, _name);
        people.push(newPerson);
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}