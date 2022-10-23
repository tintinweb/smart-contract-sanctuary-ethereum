/**
 *Submitted for verification at Etherscan.io on 2022-10-23
*/

// SPDX-License-Identifier: MIT

pragma solidity >0.8.0 <0.9.0;

contract SimpleStorage {
    uint favoriteNumber;

    struct People {
        string name;
        uint favoriteNumber;
    }

    People[] public people;

    mapping(string => uint) public nameToFavoriteNumber;

    function addPerson(string memory _name, uint _favoriteNumber) public {
        people.push(People(_name, _favoriteNumber));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    function store(uint _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint) {
        return favoriteNumber;
    }
}