// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8; // set version

contract SimpleStorage {
    // bool hasFavouriteNumber = true;
    //
    // string favouriteNumberInText = "Five";
    // int256 favouriteInt = -5;
    // address myAddress = 0xCe93AA05a79BC39B06932929Fbc5bA7fE23Eb33b;
    // byte favouriteBytes = "cat";
    uint256 public favouriteNumber;

    mapping(string => uint256) public nameToFavouriteNumber;
    struct People {
        uint256 favouriteNumber;
        string name;
    }

    People[] public people;

    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        people.push(People({favouriteNumber: _favouriteNumber, name: _name}));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }
}
// 0xd9145CCE52D386f254917e481eB44e9943F39138