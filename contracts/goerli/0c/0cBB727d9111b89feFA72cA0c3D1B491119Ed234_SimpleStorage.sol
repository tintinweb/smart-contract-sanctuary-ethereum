/**
 *Submitted for verification at Etherscan.io on 2023-02-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// pragma solidity >=0.8.7 <0.9.0;

// EVM, Etherrum Virtual Machine
// Avalanche, Fantom, Polygon

contract SimpleStorage {
    // boolean, unit, int, address, bytes

    uint256 public favoriteNumber;
    People public person = People({favoriteNumber: 2, name: "Leo"});
    People public person1 = People({favoriteNumber: 3, name: "Rachel"});

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
        retrieve();
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function add() public pure returns (uint256) {
        return (1 + 1);
    }

    // calldata: temp, can't change; memory: temp, can change; storage: permanent, can change(only array, struct and mapping need to add)
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // People memory newPerson = People({favoriteNumber: _favoriteNumber , name: _name});
        // people.push(newPerson);
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}
// 0xd9145CCE52D386f254917e481eB44e9943F39138