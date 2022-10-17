// SPDX-License-Identifier: MIT

pragma solidity 0.8.9; //0.8.12 current, but 0.8.8 is more stable

contract SimpleStorage {
    // common types: boolean, uint, int, address, bytes
    // variables functions etc can have 1 of 4 visability states.
    // public, private, external, interna
    uint256 favoriteNumber; // if not set default initialize to 0

    mapping(string => uint256) public nameToFavoriteNumber;

    //People public person = People({favoriteNumber:69,name:"Andrew"});
    People[] public people;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    function store(uint256 newFavNum) public virtual {
        favoriteNumber = newFavNum;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People({name: _name, favoriteNumber: _favoriteNumber}));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}