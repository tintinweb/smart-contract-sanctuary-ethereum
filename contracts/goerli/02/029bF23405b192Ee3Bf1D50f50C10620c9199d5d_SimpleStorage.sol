// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract SimpleStorage {
    uint256 public favoriteNumber;
    People[] public people;
    mapping(string => uint256) public yourNumber;

    struct People {
        string name;
        uint256 favoriteNumber;
    }

    //store a favorite number
    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    //function to retrieve the favorite number
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    //create a list of people with their name and favorite number
    function setPeople(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_name, _favoriteNumber));
        //map the favorite number with the person name
        yourNumber[_name] = _favoriteNumber;
    }

}