/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// EVM, Ethereum Virtual Machine
// Avalanche, Fantom, Polygon
contract SimpleStorage {

    // This gets initialized to zero!
    // <- This means that this section is a comment!
    uint256 favouriteNumber;
    mapping(string => uint256) public nameToFavouriteNumber;

    struct People {
        uint256 favouriteNumber;
        string name;
    }

    // uint256[] public favouriteNumbersList;
    People[] public people;

    function store(uint256 _favouriteNumber) public virtual{
        favouriteNumber = _favouriteNumber;
    }

    // view, pure
    // view -> cannot write state
    // pure -> cannot read or write state
    function retrieve() public view returns(uint256) {
        return favouriteNumber;
    }

    // calldata, memory, storage
    // calldata are temporary variables that cannot be modified
    // memory are temporary variables that can be modified
    // storage are permanent variables that can be modified
    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        people.push(People(_favouriteNumber, _name));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }

}

// 0xd9145CCE52D386f254917e481eB44e9943F39138