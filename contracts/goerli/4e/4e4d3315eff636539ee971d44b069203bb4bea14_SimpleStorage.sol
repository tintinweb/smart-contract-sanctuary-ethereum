/**
 *Submitted for verification at Etherscan.io on 2022-11-24
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract SimpleStorage {
    uint256 favoriteNumber;
    People[] public peoples;
    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPeople(uint256 _favoriteNumber, string memory _name) public {
        People memory newPeople = People(_favoriteNumber, _name);
        peoples.push(newPeople);
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    struct People {
        uint256 favoriteNumber;
        string name;
    }
}