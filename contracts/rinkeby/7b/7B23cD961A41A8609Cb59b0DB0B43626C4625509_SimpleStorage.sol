/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; // Their are many versions, but we should select stable version. We can create a range of versions we want to use

contract SimpleStorage {
    uint256 favoriteNumber; // this gets initialized at zero, this is also a storage evm
    mapping(string => uint256) public nameToFavoriteNumber;
    struct People {
        uint256 favoriteNumber;
        string name;
    }
    People[] public people;
    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        People memory newPerson = People({
            favoriteNumber: _favoriteNumber,
            name: _name
        });
        people.push(newPerson);
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}