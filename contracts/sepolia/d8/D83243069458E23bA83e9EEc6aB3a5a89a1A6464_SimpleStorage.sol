// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract SimpleStorage {
    uint256 public favoriteNumber;

    //struktur data yang isinya type data
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    //map type string ke uint256
    mapping(string => uint256) public nameToFavoriteNumber;

    //array
    People[] public people;

    function store(uint256 _fvNumber) public virtual {
        favoriteNumber = _fvNumber;
    }

    //pure, views
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    //calldata, memory, storage
    function addPerson(string memory _name, uint256 _fvNumber) public {
        people.push(People({favoriteNumber: _fvNumber, name: _name}));
        nameToFavoriteNumber[_name] = _fvNumber;
    }
}

//compile

// yarn add solc
//!  yarn solcjs --bin --abi --include-path node_modules/ --base-path . -o . SimpleStorage.sol