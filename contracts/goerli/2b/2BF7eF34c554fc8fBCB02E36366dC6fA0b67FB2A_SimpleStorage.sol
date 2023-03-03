//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage{

    uint256 favoriteNumber;
    Person[] public people;

    struct Person{
        uint256 favoriteNumber;
        string name;
    }
    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber)public{
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns(uint256){
        return favoriteNumber;
    }

    function createPerson(string memory _name, uint256 _favoriteNumber)public{
        people.push(Person(_favoriteNumber,_name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}

// 0xd9145CCE52D386f254917e481eB44e9943F39138