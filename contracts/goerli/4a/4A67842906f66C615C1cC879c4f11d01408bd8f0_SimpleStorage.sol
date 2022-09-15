/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract SimpleStorage {
    // this gets initialize to zero
    uint256 favoriteNumber;
    // People public person = People({favoriteNumber: 2  , name: "Ravi"});
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
        // People memory newPerson = People({favoriteNumber: _favoriteNumber, name: _name});
        people.push(People(_favoriteNumber, _name));
        // people.push(newPerson);
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    // 0xd9145CCE52D386f254917e481eB44e9943F39138
}