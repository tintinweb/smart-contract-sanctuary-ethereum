// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

contract SimpleStorage {
    uint256 public favouriteNumber; 
    mapping(string => uint256) public nameToFavouriteNumber; 

    struct People {
        uint256 favouriteNumber;
        string name;
    }
    People[] public people;
    
    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }
    function retrieve() public view returns(uint256) {
        return favouriteNumber;
    }
    function addPerson(string memory _name, uint256 _favouriteNumber) public {
            People memory newPerson = People(_favouriteNumber, _name);
            people.push(newPerson);
            nameToFavouriteNumber[_name]= _favouriteNumber ;
    }
}