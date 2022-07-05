//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract Simplestorage {
    // Solidity data types
    // boolean. uint, int, address, bytes

    // This initializes to zero
    uint256 public favouriteNumber;
    // People public person = People({favouriteNumber: 2, name:"Eni"});

    //MAPPING
    mapping(string => uint256) public nameToFavouriteNumber;

    struct People {
        uint256 favouriteNumber;
        string name;
    }
    // uint256 [] public favouriteNumber
    People[] public people;

    //functions

    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
        // uint256 testVar = 5;
    }

    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        people.push(People(_favouriteNumber, _name));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }

    // view and pure functions when called alone, don't spend gas
    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    // Storage units in solidity
    // calldata, memory, storage
}

// 0xd9145CCE52D386f254917e481eB44e9943F39138