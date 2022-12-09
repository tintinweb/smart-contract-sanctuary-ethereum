/**
 *Submitted for verification at Etherscan.io on 2022-12-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7; // First line mentioning the version of Solidity to work with

contract SimpleStorage {
    uint256 public favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    // People public person = People({
    //    favoriteNumber: 2
    //    name: "Shubham";
    // });

    People[] public people;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    function store(uint256 _favoriteNumberChanged) public virtual {
        favoriteNumber = _favoriteNumberChanged;
        // favoriteNumber = favoriteNumber + 1;
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