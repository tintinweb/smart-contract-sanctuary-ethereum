// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    uint256 favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber; 

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public peopleList; 

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber; 
    }

    function retrieve() public view returns(uint256) {
        return favoriteNumber;
    }

    function addPeopleToList(uint256 _favoriteNumber, string memory _name) public {
        peopleList.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}