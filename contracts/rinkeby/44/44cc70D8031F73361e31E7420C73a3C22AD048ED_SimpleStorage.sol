//SPDX-License-Identifier: MIT

//always start with declearing the compiler vesrion
pragma solidity ^0.8.4;

//declare a contract
contract SimpleStorage {
    //declaring a variable: type visibility name
    uint256 favouriteNumber;

    //Creating a data type
    struct people {
        uint256 favouriteNumber;
        string name;
    }

    //declaring an array
    people[] public class;

    //mapping data to each other
    mapping(string => uint256) public nametoFavouriteNUmber;

    //function (yellow: changes state, blue:no change of state)
    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        class.push(people({favouriteNumber: _favouriteNumber, name: _name}));
        nametoFavouriteNUmber[_name] = _favouriteNumber;
    }

    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }
}