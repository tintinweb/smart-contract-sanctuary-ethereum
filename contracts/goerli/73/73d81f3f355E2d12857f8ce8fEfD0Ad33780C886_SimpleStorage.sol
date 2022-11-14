// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; // sol version

contract SimpleStorage {
    uint256 aNumber;

    struct People {
        uint256 aNumber;
        string name;
    }

    //array
    People[] public people;

    //dictionary of string, int
    mapping(string => uint256) public nameOfFavoriteNumber;

    //calldata: unmodifiable temp data
    //memory: modifiedable temp data. use memory since strings are arrays
    //storage: variable data can be stored
    function addPerson(string memory _name, uint256 _number) public {
        people.push(People(_number, _name));
        nameOfFavoriteNumber[_name] = _number;
    }

    function store(uint256 number) public virtual {
        aNumber = number;
    }

    // view: readonly, not tx on network no gas spent
    function retrieve() public view returns (uint256) {
        return aNumber;
    }
}