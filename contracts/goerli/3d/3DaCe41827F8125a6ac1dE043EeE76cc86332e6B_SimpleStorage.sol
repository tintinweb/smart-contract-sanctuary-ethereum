/**
 *Submitted for verification at Etherscan.io on 2023-01-05
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7; // First line on any solidity file should be solidity version

contract SimpleStorage {
    //If not assigned anything, null value of the type is assigned to the variable. For uint, null value is 0;
    //The number beside uint is bits size. So we are storing a unsigned number of 256 bits.
    uint256 favoriteNumber;
    People[] public people;
    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}