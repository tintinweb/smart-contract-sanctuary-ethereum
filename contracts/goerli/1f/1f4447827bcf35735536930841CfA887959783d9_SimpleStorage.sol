// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

contract SimpleStorage {
    uint256 favoriteNumber;

    struct Person {
        string name;
        uint256 favNum;
    }

    Person[] public people;
    mapping(string => uint256) public personToFavNum;

    function store(uint256 _favNum) public {
        favoriteNumber = _favNum;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favNum) public {
        people.push(Person({name: _name, favNum: _favNum}));
        personToFavNum[_name] = _favNum;
    }

    function getPeople() public view returns (Person[] memory) {
        return people;
    }
}