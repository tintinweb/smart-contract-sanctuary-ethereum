/**
 *Submitted for verification at Etherscan.io on 2022-06-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// contract SimpleStorage {
//     bool hsaFaboriteNumber = true;
//     uint256 favoriteNumber = 5;
//     string favoriteNumberInText = "Five";
//     int256 favoriteInt = -5;
//     address myAddress = 0x300170eC894d281CB6392E153B17eB3Fe870D00d;
//     bytes32 favoriteBytes = "cat";
// }

contract SimpleStorage {
    uint256 public favoriteNumber;

    // People public person = People({favoriteNumber: 2, name: "Jack"});
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
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}