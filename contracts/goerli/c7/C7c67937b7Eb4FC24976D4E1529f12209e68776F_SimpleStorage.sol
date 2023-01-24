// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    uint public favoriteNumber ;
    struct People {
        uint favoriteNumber;
        string name;
    }
    mapping(string=>uint) public nameToFavoritenumber;
    function store(uint _favioriteNumber) public{
        favoriteNumber =_favioriteNumber;
    }

    function retrive() public view returns(uint){
        return favoriteNumber;
    }
    People[] public people;
    function addPerson(uint _favoriteNumber,string memory _name) public{
        people.push(People(_favoriteNumber,_name));
        nameToFavoritenumber[_name]=_favoriteNumber;
    }
    
}