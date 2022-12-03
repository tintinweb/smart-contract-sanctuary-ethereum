// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// pragma solidity >=0.8.0 <0.9.0;

contract SimpleStorage {
    uint256 favouriteNumber = 0;

    struct People {
        uint256 favouriteNumber;
        string name;
    }

    People[] public people;

    mapping(string => uint256) public nameToFav;

    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    //view, pure
    function retrive() public view returns (uint256) {
        return favouriteNumber;
    }

    function addPerson(string memory _name, uint256 _favNum) public {
        //people.push(People(_favNum, name));
        people.push(People({favouriteNumber: _favNum, name: _name}));
        nameToFav[_name] = _favNum;
    }
}