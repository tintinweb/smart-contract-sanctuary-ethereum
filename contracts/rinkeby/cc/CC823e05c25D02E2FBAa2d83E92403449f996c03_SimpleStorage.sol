// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; // version of the solidity ^ means 0.8.7 and higher version

contract SimpleStorage {
    uint256 favoriteNumber;
    // this get intialized to zero, public means it is visible

    mapping(string => uint256) public nameToFavoriteNumber;
    // get the corresponding info

    // new type (Default indexes)
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // uint256 public favoriteNumbersList;
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

// 0xd9145CCE52D386f254917e481eB44e9943F39138