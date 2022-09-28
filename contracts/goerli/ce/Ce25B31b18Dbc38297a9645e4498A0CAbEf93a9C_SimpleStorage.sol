// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; //setting version

//data types: boolean, uint, int, address, bytes, string.

//compiles into evm -> ethereum virtual machine
// avalanche, fantom, polygon.

contract SimpleStorage {
    // bool hasFavoriteNumber = false;
    // string favoriteNumberInText = "Eleven";
    // address myAddress = 0xc07094387074BbE5783d836D549CBd021aa473D4;
    // bytes32 favoriteBytes = "cat";

    //default value will be zero if not initialized
    uint256 favoriteNumber = 11;

    //mapping (similar to key value pair)
    mapping(string => uint256) public nameToFavoriteNumber;

    //struct of people
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    //array
    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
        // favoriteNumber = favoriteNumber + 1;
    }

    //view and pure functions dont use gas when ran alone.
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // function add() public pure returns(uint256) {
    //     return(1 + 1);
    // }

    //calldata, memory, storage
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}