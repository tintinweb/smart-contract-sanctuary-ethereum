//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Storage {
    uint256 public favoriteNumber;
    People public person ;

    mapping (string => uint256) public nameToFavouriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    } 

    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns(uint256){
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People({favoriteNumber: _favoriteNumber, name: _name}));
        nameToFavouriteNumber[_name] = _favoriteNumber;
    }

}