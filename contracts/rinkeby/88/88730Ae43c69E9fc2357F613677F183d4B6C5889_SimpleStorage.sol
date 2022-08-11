// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// EVM, Ethereum Virutal Machine
// Avalanche, Fantom, Polygon

contract SimpleStorage {
    // This gets initialized to zero!
    // <- This means that this section is a comment!
    uint256 favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // uint256[] public favoriteNumberList;
    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view, pure
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // calldata, memory, storage
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}
// 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4