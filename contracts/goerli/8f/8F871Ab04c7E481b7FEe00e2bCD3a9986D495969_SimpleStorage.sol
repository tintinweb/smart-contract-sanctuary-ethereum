// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; //^: any version of this and higher // >=0.8.7 <0.9.0 : defines vesrion in specific range

contract SimpleStorage {
    //similar to classes
    uint256 favoriteNumber; //automatically initialized with 0

    mapping(string => uint256) public nameToFavoriteNumber; //every possible string is initialized with 0

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    //uint256[] public favoriteNumbersList;
    People[] public people; //dynamic array without intital size

    function store(uint256 _favoriteNumber) public virtual {
        //prefix variable with underscore like convention
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        //People memory newPerson = People({favoriteNumber: _favoriteNumber, name: _name}); actually more explicit
        People memory newPerson = People(_favoriteNumber, _name);
        people.push(newPerson);
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}