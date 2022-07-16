/**
 *Submitted for verification at Etherscan.io on 2022-07-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

error PositiveNumberRequired(uint256 _favoriteNumber);
error InvalidFavoriteNumberOverwrite(string _name);
error IndexOutOfBounds(uint256 _index);

contract SimpleStorage {
    uint256 public favoriteNumber; // Initialized to null value (i.e. null for uint256 is 0)

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] internal people;

    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function personAtIndex(uint256 _index) public view returns (People memory) {
        if (people.length == 0 || _index > people.length - 1) {
            revert IndexOutOfBounds(_index);
        }
        return people[_index];
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        if (_favoriteNumber == 0) {
            revert PositiveNumberRequired(_favoriteNumber);
        }
        if (nameToFavoriteNumber[_name] != 0) {
            revert InvalidFavoriteNumberOverwrite(_name);
        }
        People memory person = People({
            name: _name,
            favoriteNumber: _favoriteNumber
        });
        people.push(person);

        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}