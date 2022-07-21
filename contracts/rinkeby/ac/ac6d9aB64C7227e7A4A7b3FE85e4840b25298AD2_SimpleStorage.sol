// I'm a comment!
// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

//pragma solidity >=0.6.0 <0.9.0;
// pragma solidity ^0.8.0;
// pragma solidity >=0.8.0 <0.9.0;

// EVM, Ethereum Virtual Machinbe
// Avalaunch, fantom ,polygon
contract SimpleStorage {
    // bool,byte32,uint256,int

    uint256 favoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }
    // uint256[] public anArray;
    People[] public people;

    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    //calldata,memory,storage

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}