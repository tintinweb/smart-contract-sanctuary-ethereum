// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8; 

// 0xd9145CCE52D386f254917e481eB44e9943F39138
contract SimpleStorage {

    // this gets init to 0
    uint256 favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // People public person = People({favoriteNumber: 2, name: "Patrick"});
    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns(uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}