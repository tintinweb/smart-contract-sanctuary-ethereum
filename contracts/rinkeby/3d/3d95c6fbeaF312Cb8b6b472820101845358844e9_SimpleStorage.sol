// SPDX-License-Identifier: mit
pragma solidity ^0.8.0;

// EVM Ethereum Virtual Machine
//Avalanche, Fantom, Polygon

contract SimpleStorage {
    uint256 favoriteNumber;

    //dynamic array [3] spec size []
    People[] public people;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    //view, pure don't require gas
    //only need to spend gas if we change the state
    //pure is for calculations
    //if contracts reed data by calling functions, you pay gass
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    //calldata (temp can't reassign), memory (memory temp can be modified), storage (permanent that can be modified)
    //used for complex data types (strucs, mappings, arrays)
    function addPerson(string calldata _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}

//0xd9145CCE52D386f254917e481eB44e9943F39138