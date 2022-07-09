//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

//EVM,Ethereum Virtual Machine
//Avalanch, Fantom,Polygon

contract SimpleStorage {
    uint256 favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    function Store(uint256 _favotiteNumber) public virtual {
        favoriteNumber = _favotiteNumber;
    }

    // view , pure
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    //calldata, memory, storage
    function addperson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}