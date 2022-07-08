/**
 *Submitted for verification at Etherscan.io on 2022-07-08
*/

// License
// SPDX-License-Identifier: MIT

// Solidity version
pragma solidity 0.8.7; // 0.8.7 and above

// pragma solidity >=0.8.7 <0.9.0; -> In between

contract SimpleStorage {
    // boolean, uint, int, address, bytes
    // bool hasFavoriteNumber = false;
    // uint256 favoriteNumber = 5;
    // string favoriteNumberInText = "Five";
    // int256 favoriteInt = -5;
    // address myAddress = 0x3575418f1ae43b15ecCa776e898FD99779030853;
    // bytes32 favoriteBytes = "cat";
    uint256 public favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    // People public person = People({favoriteNumber: 2, name: "Patrick"});
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    //view -> Read state from the contract, no update
    //pure -> Could not read from blockchain
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // calldata, memory, storage
    // calldata memory -> Only exist temporarily. calldata -> Cannot modify. memory -> Can modify.
    // storage -> outside of the scope of the function
    // favoriteNumber -> By default storage.

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}

//0xd9145CCE52D386f254917e481eB44e9943F39138