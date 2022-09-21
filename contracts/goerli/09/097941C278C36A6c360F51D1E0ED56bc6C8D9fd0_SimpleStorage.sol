// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

// ^0.8.7 :: >=0.8.7

// Avalanche, Phantom, Polygon: EVM compatible
contract SimpleStorage {
    // types: bool, uint, int, address, bytes, string
    // default: initialised to 0.
    uint256 favouriteNumber;
    People[] public person; //array
    mapping(string => uint256) public nameToFavouriteNumber;
    struct People {
        uint256 favouriteNumber;
        string name;
    }

    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    // view, pure type functions doesn't modify the contract unless they are called by other functions,
    // view - Only view access, no edit access
    // pure - no view, edit access
    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    // calldata, memory: temporary stored in
    // cd: temp, can't be modified
    // memory: temp, can be modified
    // storage: persists just like storage. can be modified
    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        person.push(People(_favouriteNumber, _name));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }

    // mappint
}

// 0xd9145CCE52D386f254917e481eB44e9943F39138