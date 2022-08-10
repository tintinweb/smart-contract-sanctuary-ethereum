// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1; //solidity version

// EVM : Ethereum Virtual Machinef

contract SimpleStorage {
    // datatypes : boolean,uint,int,address,bytes
    uint256 hasFavoriteNumber;
    //People public person = People({hasFavoriteNumber: 2, name: "Mitesh"});

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 hasFavoriteNumber;
        string name;
    }

    //uint256[] public hasFavoriteNumber;
    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        hasFavoriteNumber = _favoriteNumber;
        //uint256 testVar = 5;
    }

    function retrive() public view returns (uint256) {
        return hasFavoriteNumber;
    }

    function add() public view returns (uint256) {
        return hasFavoriteNumber;
    }

    // calldata, memory, storage
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}

// 0xd9145CCE52D386f254917e481eB44e9943F39138