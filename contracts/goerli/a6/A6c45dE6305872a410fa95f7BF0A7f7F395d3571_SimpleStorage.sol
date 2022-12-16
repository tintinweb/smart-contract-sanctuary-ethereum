/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; // Or 0.8.12 is also nice. The '^' means higher or equal. Can also put >=0.8.7 <0.9.0

contract SimpleStorage {
    // Most commun variable types -> boolean, uint, int, address, bytes

    // bool hasFavoriteNumber = true;
    // uint256 favoriteNumber = 5; // We want to be explicit witht the size of the variables
    // string favoriteNumberInText = "Five";
    // int256 favoriteInt = -5;
    // address myAddress = ;
    // byes32 favoriteBytes = "cat"; // 0x981161234311118 -> the string is automaticaly converted to bytes

    // The visibility of a variable is set to "Internal" by default
    // if set to "Public", we will have a getter function directly provided
    uint256 public favoriteNumber; // Will get the null value, here it is equal to 0

    // People public person = People({favoriteNumber: 2, name: "Patrick"});

    // When initialized, every string on the planet is initialized to 0
    mapping(string => uint256) public nameToFavoriteNumber;

    People[] public people;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // Without the "Virtual" we cannot override this function if inherited
    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // "View" and "Pure" functions don't spend gas when called alone !
    // "View" -> we just read, disallow modification of state
    // "Pure" -> Disallow read and modicition.  We can only do thing without modifying or reading variables
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function add() public pure returns (uint256) {
        return (1 + 1);
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}