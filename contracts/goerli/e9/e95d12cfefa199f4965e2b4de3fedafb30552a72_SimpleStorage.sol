/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    // instanciate fav number
    uint256 favoriteNumber;
    
    mapping(string => uint256) public nameToFavoriteNumber;

    // uint256[] public favoriteNumberList;
    People[] public people;
    
    // store fav number 
    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    // retrieve fav number
    function retrieve() public view returns(uint256){
        return favoriteNumber;
    }

    // Struct type
    struct People {
        string name;
        uint256 favoriteNumber;
    }

    // calldata, memory, storage
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_name, _favoriteNumber));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

}