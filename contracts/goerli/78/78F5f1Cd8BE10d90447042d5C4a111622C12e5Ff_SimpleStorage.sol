/**
 *Submitted for verification at Etherscan.io on 2022-09-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract SimpleStorage {
    // Types: boolean, uint, int, address, bytes
    // bool hasFavoriteNumber = true;

    uint256 public favoriteNumber; // Defaults to 0
    // Default visibility = 'internal'

    mapping(string => uint256) public nameToFavoriteNumber;

    // People public person = People({favoriteNumber: 2, name: "Jorrit"});
    People[] public people;
    // People[3] public people;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // string favoriteNumberInText = "Five";
    // int256 favoriteInt = -5;
    // address myAddress = 0xE8eABad0B502ba1cfaf01904a78037435dD148F7;
    // bytes32 favoriteBytes = "cat"; //e.g. 0x982fad3

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // View and pure functions don't spend gas
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