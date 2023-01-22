// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract simpleStorage {
    //primitive data types boolen, unit, int, address, bytes
    uint256 favouriteNumber;

    function store(uint256 _favNum) public {
        favouriteNumber = _favNum;
    }

    //view an pure functions
    function retrive() public view returns (uint256) {
        return favouriteNumber;
    }

    function add() internal pure returns (uint256) {
        return (1 + 1);
    }

    //struct
    struct People {
        uint256 favouriteNumber;
        string name;
    }

    //mappings
    mapping(string => uint256) public nameToFavoriteNumber;

    People person1 = People({favouriteNumber: 19, name: "Deejay"});

    //array
    People[] public people;

    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        people.push(People(_favouriteNumber, _name));
        // People memory newPerson = People({favouriteNumber: _favouriteNumber, name: _name});
        // people.push(newPerson);
        nameToFavoriteNumber[_name] = _favouriteNumber;
    }
}
// 0x88beE9Fd87465165849ee283838bf6E9c993c762