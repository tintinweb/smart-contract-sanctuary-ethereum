/**
 *Submitted for verification at Etherscan.io on 2022-10-17
*/

// SPDX-License-Identifier: MIT

// always specify solidity version
pragma solidity ^0.8.8;

// contract is like "class"
contract SimpleStorage {
    // variable types (boolean, uint, int, address, bytes)

    // define boolean variable
    uint256 public favoriteNumber;

    // use People constructor to make struct
    People public person = People({favoriteNumber: 2, name: "Peter"});

    // use People constructor with variable slots
    People public person2 = People("Andy", 3);

    // Array type
    People[] public people;

    // Object type
    struct People {
        string name;
        uint256 favoriteNumber;
    }

    // Map type

    mapping(string => uint256) public nameToFavoriteNumber;

    // Functions below

    function stre(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view function doesn't consume gas, but cannot modify state
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // pure function doesn't consume gas, but cannot read/write state
    function calcualte(uint256 a, uint256 b) public pure returns (uint256) {
        return a + b;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // People memory p = People({name: _name, favoriteNumber: _favoriteNumber});
        people.push(People(_name, _favoriteNumber));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}