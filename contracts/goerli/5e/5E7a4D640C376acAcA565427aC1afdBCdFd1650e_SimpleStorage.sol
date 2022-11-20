/**
 *Submitted for verification at Etherscan.io on 2022-11-20
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 favoriteNumber; //not initialized? solidity initializes to 0
    struct People {
        uint256 favoriteNumber;
        string name;
    }
    People[] public people;
    mapping(string => uint256) public nameToFavNumber;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        People memory newPerson = People({
            name: _name,
            favoriteNumber: _favoriteNumber
        });
        people.push(newPerson);
        //people.push(People(_name, _favoriteNumber))
        nameToFavNumber[_name] = _favoriteNumber;
    }
}