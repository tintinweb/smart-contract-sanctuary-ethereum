/**
 *Submitted for verification at Etherscan.io on 2022-07-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    uint256 favoriteNumber; // Initialised to zero
    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public peoples;

    // Adding virtual keyword to the function makes it overridable.
    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view, pure function are not charged ay gas.
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // Add to Array
        peoples.push(People(_favoriteNumber, _name));
        // Add to a map
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}