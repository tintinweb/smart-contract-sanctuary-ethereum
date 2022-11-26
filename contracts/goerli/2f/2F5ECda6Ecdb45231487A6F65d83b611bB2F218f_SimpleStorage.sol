/**
 *Submitted for verification at Etherscan.io on 2022-11-26
*/

// Solidity Version. ( ^ ) means above and equal version
// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// EVM, Etherium Virtual Machine
// Avalance, Fantom, Polygon

// contract is similar to class
contract SimpleStorage {
    // This gets initialized to zero, and has internal scope
    uint256 favouriteNumber;

    // map string ito uint256
    mapping(string => uint256) public nameToFavouriteNumer;

    struct People {
        uint256 favouriteNumber;
        string name;
    }

    // dynamic array
    People[] public people;

    // added virtual keyword implies overriding it
    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    // view, pure functions dont spend gas and doesn't make a contract
    function retrive() public view returns (uint256) {
        return favouriteNumber;
    }

    // calldata, memory, storage
    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        // arrayname.push(structObjectName())
        people.push(People(_favouriteNumber, _name));
        nameToFavouriteNumer[_name] = _favouriteNumber;
    }
}