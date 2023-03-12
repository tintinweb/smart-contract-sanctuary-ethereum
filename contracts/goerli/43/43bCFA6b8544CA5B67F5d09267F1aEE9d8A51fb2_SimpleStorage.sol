// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint favoriteNumber; // null = 0 in solidity

    mapping(string => uint) public nameToFavoriteNumber;

    struct People {
        uint favoriteNumber;
        string name;
    }

    //uint[] public favoriteNumberList;
    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        // _ convention for parameter name, to know that the variable is different from the global one
        favoriteNumber = _favoriteNumber;
    }

    //view, pure
    function retrieve() public view returns (uint) {
        return favoriteNumber;
    }

    //calldata(type of data can't be modified) and memory(type of data can be modified i.e. int to string) are temporal variables, exists only during the transaction where its called, storage is a permanent variables
    //array structs and mappings need to specify, (strings are arrays of bytes)
    function addPerson(string memory _name, uint _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}

//0xd9145CCE52D386f254917e481eB44e9943F39138