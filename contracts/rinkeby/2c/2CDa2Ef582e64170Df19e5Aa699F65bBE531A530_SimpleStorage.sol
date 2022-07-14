/**
 *Submitted for verification at Etherscan.io on 2022-07-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// EVM, Ethereum Virtual Machine
//  Avalanche, Fantom, Polygon

contract SimpleStorage {
    // This gets initialized to zero!
    uint256 favouriteNumber; // It creates getter function

    mapping(string => uint256) public nameToFavouriteNumber;

    struct People {
        uint256 favouriteNumber;
        string name;
    }

    // uint256[] public favouriteNumberList;
    People[] public people;

    function store(uint256 _favourtieNumber) public virtual {
        favouriteNumber = _favourtieNumber;
        // retrieve();
    }

    // view, pure -> this functions disallow modification of state!
    //            -> they also dont use gas!
    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    // calldata, memory, storage
    function addPerson(string memory _name, uint256 _favourtieNumber) public {
        // People memory newPerson = People({favouriteNumber: _favourtieNumber, name: _name});
        people.push(People(_favourtieNumber, _name));
        // people.push(newPerson);
        nameToFavouriteNumber[_name] = _favourtieNumber;
    }
}

// Note: We only spend gas whenever we modify blockchain state!