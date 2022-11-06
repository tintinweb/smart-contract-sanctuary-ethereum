/**
 *Submitted for verification at Etherscan.io on 2022-11-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8; // ^ indicator of newer version of solidity permitted 

contract SimpleStorage {
    uint256 favoriteNumber;

    

    mapping(string => uint256) public nameToFavoriteNumber;


    People[] public people;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
        favoriteNumber = favoriteNumber + 1;
        
    }

    function retrive() public view returns(uint256) {
        return favoriteNumber;

    }
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}